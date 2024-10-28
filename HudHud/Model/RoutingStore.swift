//
//  RoutingStore.swift
//  HudHud
//
//  Created by Naif Alrashed on 22/08/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import FerrostarCore
import FerrostarCoreFFI
import Foundation
import MapLibre
import MapLibreSwiftDSL
import OSLog

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

    let hudHudGraphHopperRouteProvider = HudHudGraphHopperRouteProvider(host: DebugStore().routingHost)

    @ObservedChild private(set) var ferrostarCore: FerrostarCore

    @Published var routes: [Route] = []

    private let spokenInstructionObserver = AVSpeechSpokenInstructionObserver(
        isMuted: false)

    // @StateObject var simulatedLocationProvider: SimulatedLocationProvider
    private let navigationDelegate = NavigationDelegate()

    // MARK: Computed Properties

    var alternativeRoutes: [Route] {
        self.routes.filter {
            $0.id != self.selectedRoute?.id
        }
    }

    var routePoints: ShapeSource {
        var features: [MLNPointFeature] = []
        if let waypoints = self.waypoints {
            for item in waypoints {
                switch item {
                case .myLocation:
                    continue
                case let .waypoint(poi):
                    let feature = MLNPointFeature(coordinate: poi.coordinate)
                    feature.attributes["poi_id"] = poi.id
                    features.append(feature)
                }
            }
        }
        return ShapeSource(identifier: MapSourceIdentifier.routePoints) {
            features
        }
    }

    // MARK: Lifecycle

    init(mapStore: MapStore) {
        self.mapStore = mapStore

        let provider: LocationProviding

        if DebugStore().simulateRide {
            let simulated = SimulatedLocationProvider(coordinate: .riyadh)
            simulated.warpFactor = 3
            provider = simulated
        } else {
            provider = CoreLocationProvider(
                activityType: .automotiveNavigation,
                allowBackgroundLocationUpdates: true
            )
            provider.startUpdating()
        }

        // Configure the navigation session.
        // You have a lot of flexibility here based on your use case.
        let config = SwiftNavigationControllerConfig(
            stepAdvance: .relativeLineStringDistance(
                minimumHorizontalAccuracy: 32, automaticAdvanceDistance: 10
            ),
            routeDeviationTracking: .staticThreshold(
                minimumHorizontalAccuracy: 25, maxAcceptableDeviation: 20
            ), snappedLocationCourseFiltering: .snapToRoute
        )

        self._ferrostarCore = ObservedChild(wrappedValue: FerrostarCore(
            customRouteProvider: HudHudGraphHopperRouteProvider(host: DebugStore().routingHost),
            locationProvider: provider,
            navigationControllerConfig: config
        ))

        self.ferrostarCore.delegate = self.navigationDelegate
        self.ferrostarCore.spokenInstructionObserver = self.spokenInstructionObserver
    }

    // MARK: Functions

    func startNavigation() {
        self.navigatingRoute = self.selectedRoute
    }

    func cancelCurrentRoutePlan() {
        self.routes = []
        self.potentialRoute = nil
        self.navigatingRoute = nil
        self.selectedRoute = nil
    }

    func clearRoutes() {
        self.routes.removeAll()
        self.selectedRoute = nil
    }

    func selectRoute(withId id: Int) {
        self.selectedRoute = self.routes.first(where: { $0.id == id })
    }

    func calculateRoutes(for waypoints: [Waypoint]) async throws -> [Route] {
        return try await self.hudHudGraphHopperRouteProvider.getRoutes(waypoints: waypoints)
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
        self.ferrostarCore.stopNavigation()
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
}

// MARK: - Previewable

extension RoutingStore: Previewable {
    static let storeSetUpForPreviewing = RoutingStore(mapStore: .storeSetUpForPreviewing)
}
