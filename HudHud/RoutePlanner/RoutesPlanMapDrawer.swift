//
//  RoutesPlanMapDrawer.swift
//  HudHud
//
//  Created by Naif Alrashed on 03/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Combine
import FerrostarCoreFFI
import Foundation
import MapLibre
import MapLibreSwiftDSL

// MARK: - RoutesPlanMapDrawer

/// Responsible for interacting with the map for the route planner use case
/// * draw the destinations
/// * draw the routes
/// * provide call back from the map like selected an alternative route
@Observable
@MainActor
final class RoutesPlanMapDrawer {

    // MARK: Properties

    private(set) var routes: [Route] = []
    private(set) var routeStops = ShapeSource(identifier: MapSourceIdentifier.routePoints) {}

    private(set) var alternativeRoutes: [Route] = []
    private(set) var selectedRoute: Route?

    /// using this pattern guarantees that no one outside of `Self` will send any events
    private var _routePlanEvents = PassthroughSubject<RoutePlanEvent, Never>()

    // MARK: Computed Properties

    var routePlanEvents: any Publisher<RoutePlanEvent, Never> {
        self._routePlanEvents
    }

    // MARK: Functions

    func drawRoutes(
        routes: [Route],
        selectedRoute: Route,
        waypoints: [RouteWaypoint]
    ) {
        let alternativeRoutes = routes.filter { $0.id != selectedRoute.id }

        self.alternativeRoutes = alternativeRoutes
        self.selectedRoute = selectedRoute
        self.routes = alternativeRoutes + [selectedRoute]

        self.routeStops = self.buildRouteStopsShapeSource(from: waypoints)
    }

    func clear() {
        self.routes = []
        self.alternativeRoutes = []
        self.selectedRoute = nil
        self.routeStops = ShapeSource(identifier: MapSourceIdentifier.routePoints) {}
    }

    func selectRoute(withID id: Int) {
        self._routePlanEvents.send(.didSelectRoute(routeID: id))
    }

    private func buildRouteStopsShapeSource(
        from stops: [RouteWaypoint]
    ) -> ShapeSource {
        let stopFeatures: [MLNPointFeature] = stops.compactMap { stop in
            switch stop.type {
            case .userLocation:
                return nil
            case let .location(item):
                let feature = MLNPointFeature(coordinate: item.coordinate)
                feature.attributes["poi_id"] = item.id
                return feature
            }
        }
        return ShapeSource(identifier: MapSourceIdentifier.routePoints) {
            stopFeatures
        }
    }
}

// MARK: - RoutePlanEvent

enum RoutePlanEvent: Hashable {
    case didSelectRoute(routeID: Int)
}
