//
//  NavigationVisulaization.swift
//  HudHud
//
//  Created by Ali Hilal on 17/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import Combine
import FerrostarCore
import FerrostarCoreFFI
import FerrostarMapLibreUI
import FerrostarSwiftUI
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import OSLog

@MainActor
final class NavigationVisualization: ObservableObject {

    // MARK: Nested Types

    enum Defaults {
        static let selectedRouteSourceId = "selected-route"
        static let alternativeRoutesSourceId = "alternative-route"
        static let congestionSourceId = "congestion"
        static let pointsSourceId = "points"
        static let selectedPointSourceId = "selected-point"
        static let routePointsSourceId = "route-points"
    }

    // MARK: Properties

    @Published var routes: [Route] = []
    @Published var selectedRoute: Route?
    @Published var waypoints: [ABCRouteConfigurationItem] = []
    @Published var navigationState: NavigationState?

    // MARK: Private

    private var style: MLNStyle?

    private let navigationEngine: NavigationEngine
    private let routePlanner: RoutePlanner

    private var temporaryRoutes: [Route] = []

    private var cancellables: Set<AnyCancellable> = []

    // MARK: Computed Properties

    var routePoints: ShapeSource {
        var features: [MLNPointFeature] = []

        for item in self.waypoints {
            switch item {
            case .myLocation:
                continue
            case let .waypoint(poi):
                let feature = MLNPointFeature(coordinate: poi.coordinate)
                feature.attributes["poi_id"] = poi.id
                features.append(feature)
            }
        }
        return ShapeSource(identifier: MapSourceIdentifier.routePoints) {
            features
        }
    }

    var locationprovider: LocationProviding {
        self.navigationEngine.provider
    }

    var lastLocation: CLLocation? {
        self.navigationEngine.currentLocation
    }

    var isNavigating: Bool {
        self.navigationEngine.isNavigating
    }

    var alternativeRoutes: [Route] {
        self.routes.filter { $0.id != self.selectedRoute?.id }
    }

    // MARK: Lifecycle

    init(navigationEngine: NavigationEngine, routePlanner: RoutePlanner) {
        self.navigationEngine = navigationEngine
        self.routePlanner = routePlanner
        self.listenForNavigationEvents()
    }

    // MARK: Functions

    func intilize(style: MLNStyle) {
        self.style = style
    }

    func add(_ item: ABCRouteConfigurationItem) {
        self.waypoints.append(item)
    } // refactor

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
//            self.temporaryRoutes.removeAll()
            guard let firstWaypoint = waypoints.first,
                  let lastWaypoint = waypoints.last else { return }
            let others = waypoints.filter { wapoint in
                wapoint != firstWaypoint && wapoint != lastWaypoint
            }

            self.displayRoute(from: firstWaypoint.cLCoordinate, to: lastWaypoint.cLCoordinate)
        } catch {
            Logger.routing.error("Updating routes: \(error)")
        }
    } // refactor

    func preplanRoutes(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) async throws {
        let routes = try await routePlanner.planRoutes(
            from: Waypoint(coordinate: from),
            to: Waypoint(coordinate: to)
        )
        self.temporaryRoutes = routes
    }

    func displayRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        Task { @MainActor in
            if self.temporaryRoutes.isEmpty {
                try await self.preplanRoutes(from: from, to: to)
                self.render(routes: self.routes)
            } else {
                self.render(routes: self.routes)
            }
            if let firstRoute = routes.first {
                self.selectedRoute = firstRoute
            }
        }
    }

    func startNavigation() {
        guard let selectedRoute else {
            Logger.navigationViewRating.error("No route selected to be navigated")
            return
        }
        self.navigationEngine.startNavigation(on: selectedRoute)
    }

    func stopNavigation() {
        self.navigationEngine.stopNavigation()
    }

    func selectRoute(with id: Int) {
        if let newSelectedRoute = routes.first(where: { $0.id == id }), newSelectedRoute != selectedRoute {
            self.selectedRoute = newSelectedRoute
            self.render(routes: self.routes)
        }
    }

    func clear() {
        self.clearAlternativeRoutes()
        if let style, let source = style.source(withIdentifier: Defaults.selectedRouteSourceId) as? MLNShapeSource {
            source.shape = nil
        }
        self.routes = []
        self.temporaryRoutes = []
        self.selectedRoute = nil
    }

    private func render(routes _: [Route]) {
        self.routes = self.temporaryRoutes

//        guard let style = style else {
//            Logger.navigationViewRating.error("Style not available for rendering routes")
//            return
//        }
//
//        clearAlternativeRoutes()
//
//        guard !routes.isEmpty else {
//            Logger.navigationViewRating.error("No routes available to render")
//            return
//        }
//
//        guard let selectedRoute else {
//            Logger.navigationViewRating.error("No selected route available to render")
//            return
//        }
//
//        let selectedRouteFeature = createRouteFeature(from: selectedRoute)
//        let alternativeRoutes = routes.filter { $0 != selectedRoute }
//        let alternativeRoutesFeature = createMultiRouteFeature(from: alternativeRoutes)
//
//        updateSource(withId: Defaults.selectedRouteSourceId, feature: selectedRouteFeature, in: style)
//        updateSource(withId: Defaults.alternativeRoutesSourceId, feature: alternativeRoutesFeature, in: style)
//
//        let congestionFeature = createCongestionFeature(from: routes)
//        updateSource(withId: Defaults.congestionSourceId, feature: congestionFeature, in: style)
//
//        if self.selectedRoute == nil {
//            self.selectedRoute = selectedRoute
//        }
    }

    private func createRouteFeature(from route: Route) -> MLNShape {
        let coordinates = route.geometry.map(\.clLocationCoordinate2D)
        return MLNPolylineFeature(coordinates: coordinates, count: UInt(coordinates.count))
    }

    private func createMultiRouteFeature(from routes: [Route]) -> MLNShape {
        let shapes = routes.map { route -> MLNPolylineFeature in
            let coordinates = route.geometry.map(\.clLocationCoordinate2D)
            return MLNPolylineFeature(coordinates: coordinates, count: UInt(coordinates.count))
        }
        return MLNShapeCollectionFeature(shapes: shapes)
    }

    private func createCongestionFeature(from routes: [Route]) -> MLNShape {
        let congestionSegments = routes.flatMap { route -> [MLNPolylineFeature] in
            return route.extractCongestionSegments().map { segment in
                let coordinates = segment.geometry
                let feature = MLNPolylineFeature(coordinates: coordinates, count: UInt(coordinates.count))
                feature.attributes["congestion"] = segment.level
                return feature
            }
        }
        return MLNShapeCollectionFeature(shapes: congestionSegments)
    }

    private func updateSource(withId id: String, feature: MLNShape, in style: MLNStyle) {
        if let source = style.source(withIdentifier: id) as? MLNShapeSource {
            source.shape = feature
        } else {
            let newSource = MLNShapeSource(identifier: id, shape: feature, options: nil)
            style.addSource(newSource)
        }
    }

    private func clearAlternativeRoutes() {
        guard let style else { return }

        if let source = style.source(withIdentifier: Defaults.alternativeRoutesSourceId) as? MLNShapeSource {
            source.shape = nil
        }
    }

    private func listenForNavigationEvents() {
        self.navigationEngine.navigationState.sink { [weak self] state in
            self?.navigationState = state
        }.store(in: &self.cancellables)
    }

//    private func handleRouteDeviation(_ deviation: RouteDeviation) {
//        navigationState = .devaited(deviation)
//    }
//
//    private func updateTripProgress(_ progress: TripProgress) {
//        navigationState = .progressing(progress)
//    }
//
//    private func showVisualInstructions(_ instruction: VisualInstruction?) {
//        navigationState = .visualInstruction(instruction)
//    }
//
//    private func handleSpokenInstruction(_ instruction: SpokenInstruction) {
//        navigationState = .spokenInstruction(instruction)
//    }
//
//    private func updateCurrentPositionAnnotation(_ annotation: ValhallaOsrmAnnotation?) {
//        navigationState = .currentPositionAnnotation(annotation)
//    }
//
//    private func handleArrival() {
//        navigationState = .arrived
//    }
}
