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

// MARK: - RoutingStore

//
// @MainActor
// final class RoutingStore: ObservableObject {
//
//
//    struct LocationNotEnabledError: Hashable, Error {}
//
//    // MARK: Properties
//
//    @Published private(set) var waypoints: [ABCRouteConfigurationItem]?
//    let mapStore: MapStore
//
//    @Published var potentialRoute: Route?
//    @Published var navigatingRoute: Route?
//    @Published var routes: [RouteModel] = []
//
//    let hudHudGraphHopperRouteProvider = GraphHopperRouteProvider()
//
//    // MARK: Computed Properties
//
//    var selectedRoute: RouteModel? {
//        self.routes.first(where: { $0.isSelected })
//    }
//
//    var routePoints: ShapeSource {
//        var features: [MLNPointFeature] = []
//        if let waypoints = self.waypoints {
//            for item in waypoints {
//                switch item {
//                case .myLocation:
//                    continue
//                case let .waypoint(poi):
//                    let feature = MLNPointFeature(coordinate: poi.coordinate)
//                    feature.attributes["poi_id"] = poi.id
//                    features.append(feature)
//                }
//            }
//        }
//        return ShapeSource(identifier: MapSourceIdentifier.routePoints) {
//            features
//        }
//    }
//
//    // MARK: Lifecycle
//
//    init(mapStore: MapStore) {
//        self.mapStore = mapStore
//    }
//
//    // MARK: Functions
//
//    func clearRoutes() {
//        self.routes.removeAll()
//    }
//
//    func selectRoute(withId id: Int) {
//        self.routes = self.routes.map { routeModel in
//            RouteModel(
//                route: routeModel.route,
//                isSelected: routeModel.id == id
//            )
//        }
//    }
//
//    func calculateRoutes(for waypoints: [Waypoint]) async throws -> [RouteModel] {
////        return try await self.hudHudGraphHopperRouteProvider.getRoutes(waypoints: waypoints)
////            .map { route in
////                RouteModel(route: route, isSelected: false)
////            }
//        []
//    }
//
//    func calculateRoutes(for item: ResolvedItem) async throws -> [RouteModel] {
//        guard let userLocation = await self.mapStore.userLocationStore.location(allowCached: false) else {
//            throw LocationNotEnabledError()
//        }
//        let waypoints = [Waypoint(coordinate: userLocation.coordinate), Waypoint(coordinate: item.coordinate)]
//        return try await self.calculateRoutes(for: waypoints)
//    }
//
//    func navigate(to item: ResolvedItem, with calculatedRoutesIfAvailable: [Route]?) async throws {
//        let route = if let calculatedRoutesIfAvailable {
//            calculatedRoutesIfAvailable.map { RouteModel(route: $0, isSelected: false) }
//        } else {
//            try await self.calculateRoutes(for: item)
//        }
//        self.potentialRoute = route.first?.route
//        self.mapStore.displayableItems = [DisplayableRow.resolvedItem(item)]
//        if let location = route.first?.route.waypoints.first {
//            self.waypoints = [.myLocation(location), .waypoint(item)]
//        }
//    }
//
//    func navigate(to destinations: [ABCRouteConfigurationItem]) async {
//        do {
//            let waypoints: [Waypoint] = destinations.map { destination in
//                switch destination {
//                case let .myLocation(waypoint):
//                    waypoint
//                case let .waypoint(point):
//                    Waypoint(coordinate: point.coordinate)
//                }
//            }
//            self.waypoints = destinations
//            let routes = try await self.calculateRoutes(for: waypoints)
//            self.potentialRoute = routes.first?.route
//        } catch {
//            Logger.routing.error("Updating routes: \(error)")
//        }
//    }
//
//    func add(_ item: ABCRouteConfigurationItem) {
//        self.waypoints?.append(item)
//    }
//
//    func endTrip() {
////        self.ferrostarCore.stopNavigation()
//        self.waypoints = nil
//        self.potentialRoute = nil
//        self.navigatingRoute = nil
//        self.mapStore.clearItems()
//    }
// }
//
//// MARK: - Previewable
//
// extension RoutingStore: Previewable {
//    static let storeSetUpForPreviewing = RoutingStore(mapStore: .storeSetUpForPreviewing)
// }
//
