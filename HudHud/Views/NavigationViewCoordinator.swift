//
//  NavigationViewCoordinator.swift
//  HudHud
//
//  Created by Patrick Kladek on 01.03.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import Foundation
import MapboxCoreNavigation
import MapboxDirections
import MapboxNavigation
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI

// MARK: - NavigationViewCoordinator

public class NavigationViewCoordinator: NSObject {

    // This must be weak, the UIViewRepresentable owns the MLNMapView.
    weak var mapView: NavigationMapView?
    var parent: NavigationView
    var routeController: RouteController?

    // MARK: - Lifecycle

    init(parent: NavigationView) {
        self.parent = parent
        super.init()
        self.routeController?.delegate = self
    }
}

// MARK: - MLNMapViewDelegate

extension NavigationViewCoordinator: NavigationMapViewDelegate {}

// MARK: - RouteControllerDelegate

extension NavigationViewCoordinator: RouteControllerDelegate {

    public func routeController(_: RouteController, willRerouteFrom location: CLLocation) {
        Task {
            do {
                guard let currentRoute = await self.parent.route.routeOptions.waypoints.last else { return }
                let options = NavigationRouteOptions(waypoints: [Waypoint(location: location), currentRoute])

                options.shapeFormat = .polyline6
                options.distanceMeasurementSystem = .metric
                options.attributeOptions = []

                let results = try await Toursprung.shared.calculate(host: DebugStore().routingHost, options: options)
                DispatchQueue.main.async {
                    self.parent.mapStore.routes = results
                }
            } catch {
                print("Updating routes failed: \(error)")
            }
        }
    }

    public func routeController(_: RouteController, didFailToRerouteWith error: any Error) {
        print("Failed to reroute: \(error.localizedDescription)")
    }

    public func routeController(_: RouteController, didRerouteAlong route: Route, reason _: RouteController.RerouteReason) {
        self.parent.route = route
        print("didRerouteAlong new route \(route)")
    }

    public func routeController(_ routeController: RouteController, shouldRerouteFrom location: CLLocation) -> Bool {
        return !routeController.userIsOnRoute(location)
    }

}
