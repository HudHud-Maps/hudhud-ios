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
    @Published var navigatingRoute: Route?

    let hudHudGraphHopperRouteProvider = HudHudGraphHopperRouteProvider()

    let ferrostarCore: FerrostarCore

    private let spokenInstructionObserver = AVSpeechSpokenInstructionObserver(
        isMuted: false)

    // @StateObject var simulatedLocationProvider: SimulatedLocationProvider
    private let navigationDelegate = NavigationDelegate()

    // MARK: Computed Properties

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

        provider = CoreLocationProvider(
            activityType: .automotiveNavigation,
            allowBackgroundLocationUpdates: true
        )
        provider.startUpdating()

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
        let something = FerrostarCore(
            customRouteProvider: HudHudGraphHopperRouteProvider(),
            locationProvider: provider,
            navigationControllerConfig: config
        )

        self.ferrostarCore = something

        something.delegate = self.navigationDelegate

        // Initialize text-to-speech; note that this is NOT automatic.
        // You must set a spokenInstructionObserver.
        // Fortunately, this is pretty easy with the provided class
        // backed by AVSpeechSynthesizer.
        // You can customize the instance it further as needed,
        // or replace with your own.
        something.spokenInstructionObserver = self.spokenInstructionObserver
    }

    // MARK: Functions

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

    func navigate(to item: ResolvedItem, with calculatedRoutesIfAvailable: [Route]?) async throws {
        let route = if let calculatedRoutesIfAvailable {
            calculatedRoutesIfAvailable
        } else {
            try await self.calculateRoutes(for: item)
        }
        self.potentialRoute = route.first
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
        self.waypoints = nil
        self.potentialRoute = nil
    }
}

// MARK: - Previewable

extension RoutingStore: Previewable {
    static let storeSetUpForPreviewing = RoutingStore(mapStore: .storeSetUpForPreviewing)
}
