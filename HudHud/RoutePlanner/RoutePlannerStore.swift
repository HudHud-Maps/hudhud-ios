//
//  RoutePlannerStore.swift
//  HudHud
//
//  Created by Naif Alrashed on 30/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import Combine
import CoreLocation
import FerrostarCoreFFI
import Foundation

// MARK: - RoutePlannerStore

@Observable
@MainActor
final class RoutePlannerStore {

    // MARK: Properties

    var state: RoutePlanningState = .initialLoading

    private let initialDestination: ResolvedItem
    private let sheetStore: SheetStore
    private let userLocationStore: UserLocationStore
    private let routesPlanMapDrawer: RoutesPlanMapDrawer
    private let mapStore: MapStore
    private let routePlanner = RoutePlanner(
        routingService: GraphHopperRouteProvider()
    )
    private let routingStore: RoutingStore
    private var routeMapEventSubscription: AnyCancellable?

    // MARK: Lifecycle

    init(
        sheetStore: SheetStore,
        userLocationStore: UserLocationStore,
        mapStore: MapStore,
        routingStore: RoutingStore,
        routesPlanMapDrawer: RoutesPlanMapDrawer,
        destination: ResolvedItem
    ) {
        self.initialDestination = destination
        self.sheetStore = sheetStore
        self.mapStore = mapStore
        self.userLocationStore = userLocationStore
        self.routingStore = routingStore
        self.routesPlanMapDrawer = routesPlanMapDrawer
        Task {
            await self.fetchRoutePlanForFirstTime()
        }
        self.bindMapEvents()
    }

    // MARK: Functions

    func didChangeHeight(to height: CGFloat) {
        let height: Detent = .height(height)
        self.sheetStore.currentSheet.detentData.value = DetentData(
            selectedDetent: height,
            allowedDetents: [height]
        )
    }

    func addNewRoute() {
        self.sheetStore.show(
            .navigationAddSearchView { [weak self] newDestination in
                guard let self else { return }
                self.state.destinations.append(RouteWaypoint(
                    type: .location(newDestination),
                    title: newDestination.title
                ))
                Task {
                    await self.fetchRoutePlan(for: self.state.destinations)
                }
            }
        )
    }

    func startNavigation() {
        self.routingStore.startNavigation()
    }

    func swap() async {
        guard self.state.canSwap else { return }
        self.state.destinations.reverse()
        let destinations = self.state.destinations
        self.state = .initialLoading
        await self.fetchRoutePlan(for: destinations)
    }

    func remove(_ destination: RouteWaypoint) async {
        self.state.destinations.removeAll(where: { $0 == destination })
        await self.fetchRoutePlan(for: self.state.destinations)
    }

    private func fetchRoutePlanForFirstTime() async {
        guard let userLocation = await self.userLocationStore.location(allowCached: false) else {
            self.state = .locationNotEnabled
            return
        }
        let initialDestinations: [RouteWaypoint] = [
            RouteWaypoint(
                type: .userLocation(Coordinates(
                    latitude: userLocation.coordinate.latitude,
                    longitude: userLocation.coordinate.longitude
                )),
                title: "User Location"
            ),
            RouteWaypoint(
                type: .location(self.initialDestination),
                title: self.initialDestination.title
            )
        ]
        await self.fetchRoutePlan(for: initialDestinations)
    }

    private func fetchRoutePlan(for destinations: [RouteWaypoint]) async {
        guard destinations.count > 1 else {
            self.state = .errorFetchignRoute
            return
        }
        var waypoints = destinations.map { destination in
            let location = switch destination.type {
            case let .location(destinationItem):
                destinationItem.coordinate
            case let .userLocation(coordinates):
                coordinates.clLocationCoordinate2D
            }
            return Waypoint(
                coordinate: GeographicCoordinate(
                    cl: location
                ),
                kind: .break
            )
        }
        do {
            let fromWaypoint = waypoints.removeFirst()
            let destinationWaypoint = waypoints.removeLast()

            let routes = try await self.routePlanner.planRoutes(
                from: fromWaypoint,
                to: destinationWaypoint,
                waypoints: waypoints
            )
            guard let selectedRoute = routes.first else {
                throw RoutingError.routing(.noRoute(message: "No route found"))
            }
            let plan = RoutePlan(
                waypoints: destinations,
                routes: routes,
                selectedRoute: selectedRoute
            )
            self.state = .loaded(plan: plan)
            self.drawRoutes(in: plan)
        } catch {
            self.state = .errorFetchignRoute
        }
    }

    private func drawRoutes(in plan: RoutePlan) {
        self.routesPlanMapDrawer.drawRoutes(
            routes: plan.routes,
            selectedRoute: plan.selectedRoute,
            waypoints: plan.waypoints
        )
    }

    private func bindMapEvents() {
        self.routeMapEventSubscription = self.routesPlanMapDrawer.routePlanEvents.sink { [weak self] event in
            guard let self else { return }
            switch event {
            case let .didSelectRoute(routeID):
                if case var .loaded(plan) = self.state,
                   let newSelectedRoute = plan.routes.first(where: { $0.id == routeID }) {
                    plan.selectedRoute = newSelectedRoute
                    self.state = .loaded(plan: plan)
                    self.drawRoutes(in: plan)
                }
            }
        }
    }
}

// MARK: - RoutePlanningState

enum RoutePlanningState: Hashable {
    case initialLoading
    case locationNotEnabled
    case errorFetchignRoute
    case loaded(plan: RoutePlan)

    // MARK: Computed Properties

    var destinations: [RouteWaypoint] {
        get {
            switch self {
            case .initialLoading, .locationNotEnabled, .errorFetchignRoute:
                []
            case let .loaded(plan):
                plan.waypoints
            }
        }
        set {
            switch self {
            case let .loaded(plan):
                self = .loaded(plan: RoutePlan(waypoints: newValue, routes: plan.routes, selectedRoute: plan.selectedRoute))
            case .errorFetchignRoute, .initialLoading, .locationNotEnabled:
                break
            }
        }
    }

    var canSwap: Bool {
        self.destinations.count == 2
    }

    var canRemove: Bool {
        self.destinations.count > 2
    }

    var canDrag: Bool {
        self.destinations.count > 2
    }
}

// MARK: - Coordinates

struct Coordinates: Hashable {

    // MARK: Properties

    let latitude: Double
    let longitude: Double

    // MARK: Computed Properties

    var clLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }

    // MARK: Lifecycle

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    init(_ coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
}

// MARK: - RouteWaypoint

struct RouteWaypoint: Hashable {

    // MARK: Nested Types

    enum RouteWaypointType: Hashable {
        case userLocation(Coordinates)
        case location(ResolvedItem)
    }

    // MARK: Properties

    let type: RouteWaypointType
    let title: String
}

// MARK: - RoutePlan

struct RoutePlan: Hashable {
    var waypoints: [RouteWaypoint]
    var routes: [Route]
    var selectedRoute: Route
}

// MARK: - RoutePlannerStore + Previewable

extension RoutePlannerStore: Previewable {
    static let storeSetUpForPreviewing = RoutePlannerStore(
        sheetStore: .storeSetUpForPreviewing,
        userLocationStore: .storeSetUpForPreviewing,
        mapStore: .storeSetUpForPreviewing,
        routingStore: .storeSetUpForPreviewing,
        routesPlanMapDrawer: RoutesPlanMapDrawer(),
        destination: .artwork
    )
}
