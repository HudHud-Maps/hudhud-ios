//
//  RoutePlannerStore.swift
//  HudHud
//
//  Created by Naif Alrashed on 30/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
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
    private let mapStore: MapStore
    private let routePlanner = RoutePlanner(
        routingService: GraphHopperRouteProvider()
    )
    private let routingStore: RoutingStore

    // MARK: Lifecycle

    init(
        sheetStore: SheetStore,
        userLocationStore: UserLocationStore,
        mapStore: MapStore,
        routingStore: RoutingStore,
        destination: ResolvedItem
    ) {
        self.initialDestination = destination
        self.sheetStore = sheetStore
        self.mapStore = mapStore
        self.userLocationStore = userLocationStore
        self.routingStore = routingStore
        Task {
            await self.fetchRoutePlanForFirstTime()
        }
    }

    // MARK: Functions

    func onAppear() {
        guard case .loaded = self.state else { return }
        self.sheetStore.currentSheet.detentData.value = DetentData(
            selectedDetent: .third,
            allowedDetents: [.third]
        )
    }

    func addNewRoute() {
        fatalError("show the add route page here")
        self.sheetStore.show(.debugView)
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

    private func fetchRoutePlanForFirstTime() async {
        let initialDestinations: [RouteWaypoint] = [
            RouteWaypoint(
                type: .userLocation,
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
        guard let userLocation = await self.userLocationStore.location(allowCached: false) else {
            self.state = .locationNotEnabled
            return
        }
        guard destinations.count > 1 else {
            self.state = .errorFetchignRoute
            return
        }
        var waypoints = destinations.map { destination in
            let location = switch destination.type {
            case let .location(destinationItem):
                destinationItem.coordinate
            case .userLocation:
                userLocation.coordinate
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
            switch self.sheetStore.currentSheet.sheetType {
            case let .routePlanner(store) where store === self:
                self.sheetStore.currentSheet.detentData.value = DetentData(
                    selectedDetent: .third,
                    allowedDetents: [.third]
                )
            default:
                break
            }
        } catch {
            self.state = .errorFetchignRoute
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
        destination: .artwork
    )
}
