//
//  RoutingStore.swift
//  HudHud
//
//  Created by Naif Alrashed on 22/08/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import Combine
import FerrostarCore
import FerrostarCoreFFI
import Foundation
import MapLibre
import MapLibreSwiftDSL
import OSLog

// MARK: - AppEvents

enum AppEvents {
    case startNavigation
    case stopNavigation

    // MARK: Static Properties

    static let publisher = PassthroughSubject<AppEvents, Never>()
}

// MARK: - RoutingStore

@MainActor
final class RoutingStore: ObservableObject {

    // MARK: Nested Types

    /*
     enum NavigationProgress {
         case none
         case navigating
         case feedback
     }
     */

    // MARK: - Internal

    struct LocationNotEnabledError: Hashable, Error {}

    // MARK: Properties

    @Published private(set) var waypoints: [ABCRouteConfigurationItem]?
    // @Published private(set) var navigationProgress: NavigationProgress = .none
    let mapStore: MapStore

    // route that the user might choose, but still didn't choose yet
    @Published var potentialRoute: Route?

    // if this is set, that means that the user is currently navigating using this route
    @Published private(set) var navigatingRoute: Route?

    @Published private(set) var selectedRoute: Route?

    let hudHudGraphHopperRouteProvider = GraphHopperRouteProvider()

    @Published var routes: [Route] = []

    @Feature(.enableNewRoutePlanner, defaultValue: false) private var enableNewRoutePlanner: Bool

    @ObservedChild private var spokenInstructionObserver = SpokenInstructionObserver.initAVSpeechSynthesizer(isMuted: false)

    // @StateObject var simulatedLocationProvider: SimulatedLocationProvider
    private let navigationDelegate = NavigationDelegate()
    private let routesPlanMapDrawer: RoutesPlanMapDrawer
    private var routePlanSubscriptions: Set<AnyCancellable> = []

    // MARK: Computed Properties

    var alternativeRoutes: [Route] {
        self.routes.filter {
            $0.id != self.selectedRoute?.id
        }
    }

    // MARK: Lifecycle

    init(mapStore: MapStore, routesPlanMapDrawer: RoutesPlanMapDrawer) {
        self.mapStore = mapStore
        self.routesPlanMapDrawer = routesPlanMapDrawer
        self.bindRoutePlanActions()
    }

    // MARK: Functions

    func startNavigation() {
        self.navigatingRoute = self.selectedRoute
        AppEvents.publisher.send(.startNavigation) // to mitigate the issue until we find a proper solution
    }

    func startNavigation(to route: Route) {
        self.selectedRoute = route
        self.startNavigation()
    }

    func cancelCurrentRoutePlan() {
        self.routes = []
        self.potentialRoute = nil
        self.navigatingRoute = nil
        self.selectedRoute = nil
    }

    func clearAlternativeRoutes() {
        self.routes.removeAll(where: { $0.id != self.selectedRoute?.id })
    }

    func clearRoutes() {
        self.routes.removeAll()
        self.selectedRoute = nil
    }

    func selectRoute(withId id: Int) {
        self.selectedRoute = self.routes.first(where: { $0.id == id })
    }

    func calculateRoutes(for waypoints: [Waypoint]) async throws -> [Route] {
        var waypoints = waypoints
        let firstWaypoint = waypoints.removeFirst()
        let lastWaypoint = waypoints.removeLast()

        let routes = try await self.hudHudGraphHopperRouteProvider.calculateRoute(
            from: firstWaypoint,
            to: lastWaypoint,
            passingBy: waypoints
        )
        return routes
    }

    func calculateRoutes(for item: ResolvedItem) async throws -> [Route] {
        guard let userLocation = await self.mapStore.userLocationStore.location(allowCached: false) else {
            throw LocationNotEnabledError()
        }
        let waypoints = [Waypoint(coordinate: userLocation.coordinate), Waypoint(coordinate: item.coordinate)]
        return try await self.calculateRoutes(for: waypoints)
    }

    func showRoutes(to item: ResolvedItem, with calculatedRoutesIfAvailable: [Route]?) async throws {
        let route = if let calculatedRoutesIfAvailable {
            calculatedRoutesIfAvailable
        } else {
            try await self.calculateRoutes(for: item)
        }
        self.potentialRoute = route.first
        self.routes = route
        self.selectRoute(withId: self.routes.first?.id ?? 0)
        self.mapStore.displayableItems = [DisplayableRow.resolvedItem(item)]
        if let location = route.first?.waypoints.first {
            self.waypoints = [.myLocation(location), .waypoint(item)]
        }
    }

    func navigate(to destinations: [ABCRouteConfigurationItem]) async {
        do {
            let waypoints: [Waypoint] = destinations.map { destination in
                switch destination {
                case let .myLocation(waypoint):
                    waypoint
                case let .waypoint(point):
                    Waypoint(coordinate: point.coordinate)
                }
            }
            self.waypoints = destinations
            let routes = try await self.calculateRoutes(for: waypoints)
            self.potentialRoute = routes.first
        } catch {
            Logger.routing.error("Updating routes: \(error)")
        }
    }

    func add(_ item: ABCRouteConfigurationItem) {
        self.waypoints?.append(item)
    }

    func endTrip() {
        AppEvents.publisher.send(.stopNavigation)
        self.waypoints = nil
        self.potentialRoute = nil
        self.navigatingRoute = nil
        self.mapStore.clearItems()
    }
}

// MARK: - Private

private extension RoutingStore {
    func reroute(with route: Route) async {
        self.navigatingRoute = route
    }

    func bindRoutePlanActions() {
        self.routesPlanMapDrawer.routePlanEvents.sink { [weak self] event in
            guard let self, !self.enableNewRoutePlanner else { return }
            switch event {
            case let .didSelectRoute(routeID):
                if let route = self.routes.first(where: { $0.id == routeID }) {
                    self.selectedRoute = route
                }
            }
        }
        .store(in: &self.routePlanSubscriptions)
        Publishers.CombineLatest(self.$routes, self.$selectedRoute).sink { [weak self] routes, selectedRoute in
            guard let self, !self.enableNewRoutePlanner else { return }
            if routes.isEmpty {
                self.routesPlanMapDrawer.clear()
            } else if let selectedRoute = selectedRoute ?? routes.first {
                self.routesPlanMapDrawer.drawRoutes(
                    routes: routes,
                    selectedRoute: selectedRoute,
                    waypoints: (self.waypoints ?? []).map { waypoint in
                        switch waypoint {
                        case let .myLocation(waypoint):
                            RouteWaypoint(type: .userLocation(Coordinates(waypoint.cLCoordinate)), title: "User Location")
                        case let .waypoint(item):
                            RouteWaypoint(type: .location(item), title: item.title)
                        }
                    }
                )
            }
        }
        .store(in: &self.routePlanSubscriptions)
    }
}

// MARK: - Previewable

extension RoutingStore: Previewable {
    static let storeSetUpForPreviewing = RoutingStore(mapStore: .storeSetUpForPreviewing, routesPlanMapDrawer: RoutesPlanMapDrawer())
}
