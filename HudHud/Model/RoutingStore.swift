//
//  RoutingStore.swift
//  HudHud
//
//  Created by Naif Alrashed on 22/08/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import Foundation
import MapboxCoreNavigation
import MapboxDirections
import MapboxNavigation
import MapLibre
import MapLibreSwiftDSL
import OSLog

// MARK: - RoutingStore

@MainActor
final class RoutingStore: ObservableObject {

    // MARK: Nested Types

    enum NavigationProgress {
        case none
        case navigating
        case feedback
    }

    // MARK: - Internal

    struct LocationNotEnabledError: Hashable, Error {}

    // MARK: Properties

    @Published private(set) var waypoints: [ABCRouteConfigurationItem]?
    @Published private(set) var navigationProgress: NavigationProgress = .none
    let mapStore: MapStore

    // route that the user might choose, but still didn't choose yet
    @Published private(set) var potentialRoute: RoutingService.RouteCalculationResult?

    // if this is set, that means that the user is currently navigating using this route
    @Published private(set) var navigatingRoute: Route?

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
    }

    // MARK: Functions

    func calculateRoute(for waypoints: [Waypoint]) async throws -> RoutingService.RouteCalculationResult {
        let options = NavigationRouteOptions(waypoints: waypoints, profileIdentifier: .automobileAvoidingTraffic)
        options.shapeFormat = .polyline6
        options.distanceMeasurementSystem = .metric
        options.attributeOptions = [.congestionLevel]

        // Calculate the routes
        let result = try await RoutingService.shared.calculate(host: DebugStore().routingHost, options: options)

        // Return the routes from the result
        return result
    }

    func calculateRoute(for item: ResolvedItem) async throws -> RoutingService.RouteCalculationResult {
        guard let userLocation = self.mapStore.mapView?.userLocation?.location else {
            throw LocationNotEnabledError()
        }
        let waypoints = [Waypoint(location: userLocation), Waypoint(coordinate: item.coordinate)]
        return try await self.calculateRoute(for: waypoints)
    }

    func navigate(to item: ResolvedItem, with calculatedRouteIfAvailable: RoutingService.RouteCalculationResult? = nil) async throws {
        let route = if let calculatedRouteIfAvailable {
            calculatedRouteIfAvailable
        } else {
            try await self.calculateRoute(for: item)
        }
        self.potentialRoute = route
        self.mapStore.displayableItems = [DisplayableRow.resolvedItem(item)]
        if let location = route.waypoints.first {
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
            let routes = try await self.calculateRoute(for: waypoints)
            self.potentialRoute = routes
        } catch {
            Logger.routing.error("Updating routes: \(error)")
        }
    }

    func assign(to navigationController: NavigationViewController, shouldSimulateRoute: Bool) {
        navigationController.delegate = self

        switch self.navigationProgress {
        case .none:
            if let route = self.navigatingRoute {
                if shouldSimulateRoute {
                    let locationManager = SimulatedLocationManager(route: route)
                    locationManager.speedMultiplier = 2
                    navigationController.startNavigation(with: route, animated: true, locationManager: locationManager)
                } else {
                    navigationController.startNavigation(with: route, animated: true)
                }
                self.navigationProgress = .navigating
            } else {
                navigationController.mapView.userTrackingMode = self.mapStore.trackingState == .keepTracking ? .followWithCourse : .none
                navigationController.mapView.showsUserLocation = self.mapStore.userLocationStore.permissionStatus.isEnabled && self.mapStore.streetViewScene == nil
            }
        case .navigating:
            if let route = self.navigatingRoute {
                navigationController.route = route
            } else {
                navigationController.endNavigation()
                self.navigationProgress = .feedback
            }
        case .feedback:
            break
        }
    }

    func add(_ item: ABCRouteConfigurationItem) {
        self.waypoints?.append(item)
    }

    func navigate(to route: Route) {
        self.potentialRoute?.routes = [route]
        self.navigatingRoute = route
    }

    func endTrip() {
        self.waypoints = nil
        self.potentialRoute = nil
        self.navigationProgress = .none
        self.potentialRoute?.routes.removeAll()
        self.mapStore.clearItems()
    }
}

// MARK: - NavigationMapViewDelegate

extension RoutingStore: NavigationMapViewDelegate {

    func navigationViewController(_: NavigationViewController, didSelect route: Route) {
        // Remove the selected route if it exists in the array
        self.potentialRoute?.routes.removeAll(where: { $0 == route })

        // Insert the selected route at the beginning of the array
        self.potentialRoute?.routes.insert(route, at: 0)

        // Update the map with the reordered routes
        if let route = self.potentialRoute?.routes {
            self.mapStore.mapView?.showRoutes(route)
        }
    }
}

// MARK: - NavigationViewControllerDelegate

extension RoutingStore: NavigationViewControllerDelegate {

    nonisolated func navigationViewControllerDidFinishRouting(_: NavigationViewController) {
        Task { @MainActor in
            self.navigatingRoute = nil
        }
    }

    nonisolated func navigationViewController(_ navigationViewController: NavigationViewController, shouldRerouteFrom location: CLLocation) -> Bool {
        return navigationViewController.routeController?.userIsOnRoute(location) == false
    }

    nonisolated func navigationViewController(_: NavigationViewController, willRerouteFrom location: CLLocation) {
        Task {
            do {
                guard let currentRoute = await self.navigatingRoute?.routeOptions.waypoints.last else { return }

                let routes = try await self.calculateRoute(for: [Waypoint(location: location), currentRoute])
                if let route = routes.routes.first {
                    await self.reroute(with: route)
                }
            } catch {
                Logger.routing.error("Updating routes failed: \(error.localizedDescription)")
            }
        }
    }

    nonisolated func navigationViewController(_: NavigationViewController, didFailToRerouteWith error: any Error) {
        Task { @MainActor in
            Logger.routing.error("Failed to reroute: \(error.localizedDescription)")
        }
    }

    nonisolated func navigationViewController(_: NavigationViewController, didRerouteAlong route: Route) {
        Task { @MainActor in
            self.navigatingRoute = route
            Logger.routing.info("didRerouteAlong new route \(route)")
        }
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
