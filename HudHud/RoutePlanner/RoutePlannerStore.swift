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

@Observable @MainActor
final class RoutePlannerStore {

    // MARK: Properties

    var state: RoutePlanningState = .initialLoading

    private let initialDestination: DestinationPointOfInterest
    private let sheetStore: SheetStore
    private let userLocationStore: UserLocationStore
    private let routesPlanMapDrawer: RoutesPlanMapDrawer
    private let mapStore: MapStore
    private let routePlanner = RoutePlanner(routingService: GraphHopperRouteProvider())
    private let routingStore: RoutingStore
    private var routeMapEventSubscription: AnyCancellable?

    // MARK: Lifecycle

    init(sheetStore: SheetStore,
         userLocationStore: UserLocationStore,
         mapStore: MapStore,
         routingStore: RoutingStore,
         routesPlanMapDrawer: RoutesPlanMapDrawer,
         destination: DestinationPointOfInterest) {
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
        guard let selectedRoute = self.state.selectedRoute else { return }
        self.routesPlanMapDrawer.clear()
        self.routingStore.startNavigation(to: selectedRoute)
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
}

// MARK: - Private

private extension RoutePlannerStore {

    func fetchRoutePlanForFirstTime() async {
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

    func fetchRoutePlan(for destinations: [RouteWaypoint]) async {
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

    func drawRoutes(in plan: RoutePlan) {
        self.routesPlanMapDrawer.drawRoutes(
            routes: plan.routes,
            selectedRoute: plan.selectedRoute,
            waypoints: plan.waypoints
        )
    }

    func bindMapEvents() {
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

// MARK: - Previewable

extension RoutePlannerStore: Previewable {

    static let storeSetUpForPreviewing = RoutePlannerStore(sheetStore: .storeSetUpForPreviewing,
                                                           userLocationStore: .storeSetUpForPreviewing,
                                                           mapStore: .storeSetUpForPreviewing,
                                                           routingStore: .storeSetUpForPreviewing,
                                                           routesPlanMapDrawer: RoutesPlanMapDrawer(),
                                                           destination: .artwork)
}
