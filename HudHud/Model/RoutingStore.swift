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

    private var cameraTask: Task<Void, Error>?

    // MARK: Computed Properties

    @Published private(set) var routes: RoutingService.RouteCalculationResult? {
        didSet {
            if let routes, self.mapStore.path.contains(RoutingService.RouteCalculationResult.self) == false {
                self.mapStore.path.append(routes)
                self.cameraTask?.cancel()
                self.cameraTask = Task {
                    try await Task.sleep(nanoseconds: 100 * NSEC_PER_MSEC)
                    try Task.checkCancellation()
                    self.mapStore.updateCamera(state: .route(self.routes))
                }
            }
        }
    }

    @Published private(set) var navigatingRoute: Route? {
        didSet {
            if let elements = try? self.mapStore.path.elements() {
                Logger.navigationPath.log("path now: \(elements)")
                self.mapStore.updateSelectedSheetDetent(to: elements.last)
            }
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
    }

    // MARK: Functions

    // Unified route calculation function
    func calculateRoute(
        from location: CLLocation,
        to destination: CLLocationCoordinate2D?,
        additionalWaypoints: [Waypoint] = []
    ) async throws -> RoutingService.RouteCalculationResult {
        let startWaypoint = Waypoint(location: location)

        var waypoints = [startWaypoint]
        if let destinationCoordinate = destination {
            let destinationWaypoint = Waypoint(coordinate: destinationCoordinate)
            waypoints.append(destinationWaypoint)
        }
        waypoints.append(contentsOf: additionalWaypoints)

        return try await self.calculateRoute(for: waypoints)
    }

    func calculateRoute(for waypoints: [Waypoint]) async throws -> RoutingService.RouteCalculationResult {
        let options = NavigationRouteOptions(waypoints: waypoints, profileIdentifier: .automobileAvoidingTraffic)
        options.shapeFormat = .polyline6
        options.distanceMeasurementSystem = .metric
        options.attributeOptions = []

        // Calculate the routes
        let result = try await RoutingService.shared.calculate(host: DebugStore().routingHost, options: options)

        // Return the routes from the result
        return result
    }

    func calculateRoute(for item: ResolvedItem) async throws -> RoutingService.RouteCalculationResult {
        guard let userLocation = await self.mapStore.userLocationStore.location(allowCached: false) else {
            throw LocationNotEnabledError()
        }
        let waypoints = [Waypoint(location: userLocation), Waypoint(coordinate: item.coordinate)]
        return try await self.calculateRoute(for: waypoints)
    }

    func navigate(to item: ResolvedItem, with route: RoutingService.RouteCalculationResult) {
        self.routes = route
        self.mapStore.displayableItems = [DisplayableRow.resolvedItem(item)]
        if let location = route.waypoints.first {
            self.waypoints = [.myLocation(location), .waypoint(item)]
        }
    }

    func navigate(to destinations: [ABCRouteConfigurationItem]) async throws {
        let waypoints: [Waypoint] = destinations.map { destination in
            switch destination {
            case let .myLocation(waypoint):
                waypoint
            case let .waypoint(point):
                Waypoint(coordinate: point.coordinate)
            }
        }
        let routes = try await self.calculateRoute(for: waypoints)
        self.waypoints = destinations
        self.routes = routes
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
                navigationController.mapView.showsUserLocation = self.mapStore.userLocationStore.isLocationPermissionEnabled && self.mapStore.streetViewScene == nil
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
        if self.navigatingRoute == nil {
            self.navigatingRoute = route
        } else {
            self.navigatingRoute = nil
        }
    }

    func endTrip() {
        self.waypoints = nil
        self.routes = nil
        self.navigationProgress = .none
    }
}

// MARK: - Previewable

extension RoutingStore: Previewable {
    static let storeSetUpForPreviewing = RoutingStore(mapStore: .storeSetUpForPreviewing)
}

// MARK: - NavigationViewControllerDelegate

extension RoutingStore: NavigationViewControllerDelegate {

    func navigationViewControllerDidFinishRouting(_: NavigationViewController) {
        self.navigatingRoute = nil
    }

    func navigationViewController(_ navigationViewController: NavigationViewController, shouldRerouteFrom location: CLLocation) -> Bool {
        return navigationViewController.routeController?.userIsOnRoute(location) == false
    }

    func navigationViewController(_: NavigationViewController, willRerouteFrom location: CLLocation) {
        Task {
            do {
                guard let currentRoute = self.navigatingRoute?.routeOptions.waypoints.last else { return }
                let routes = try await self.calculateRoute(from: location, to: nil, additionalWaypoints: [currentRoute])
                if let route = routes.routes.first {
                    await self.reroute(with: route)
                }
            } catch {
                Logger.routing.error("Updating routes failed: \(error.localizedDescription)")
            }
        }
    }

    func navigationViewController(_: NavigationViewController, didFailToRerouteWith error: any Error) {
        Logger.routing.error("Failed to reroute: \(error.localizedDescription)")
    }

    func navigationViewController(_: NavigationViewController, didRerouteAlong route: Route) {
        self.navigatingRoute = route
        Logger.routing.info("didRerouteAlong new route \(route)")
    }
}

private extension RoutingStore {
    func reroute(with route: Route) async {
        self.navigatingRoute = route
    }
}
