//
//  NavigationView.swift
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
import SwiftUI

typealias JSONDictionary = [String: Any]

// MARK: - NavigationView

public struct NavigationView: UIViewControllerRepresentable {

    public typealias UIViewControllerType = NavigationViewController

    var route: Route
    let styleURL: URL
    @ObservedObject var debugSettings: DebugStore
    @ObservedObject var mapStore: MapStore

    // MARK: - Lifecycle

    init(route: Route, styleURL: URL, debugSettings: DebugStore, mapStore: MapStore) {
        self.route = route
        self.styleURL = styleURL
        self.debugSettings = debugSettings
        self.mapStore = mapStore
    }

    // MARK: - Public

    public func makeUIViewController(context: Context) -> MapboxNavigation.NavigationViewController {
        let locationManager: NavigationLocationManager?
        if self.debugSettings.simulateRide {
            let simulatedLocationManager = SimulatedLocationManager(route: self.route)
            simulatedLocationManager.speedMultiplier = 2
            locationManager = simulatedLocationManager
        } else {
            locationManager = nil
        }
        let routeVoice = HudHudRouteVoiceController()
        let directions = Directions(accessToken: nil, host: debugSettings.routingHost)
        let dayStyle = CustomDayStyle()
        dayStyle.mapStyleURL = self.styleURL

        let nightStyle = CustomNightStyle()
        nightStyle.mapStyleURL = self.styleURL

        let navigationController = NavigationViewController(for: self.route, directions: directions, styles: [dayStyle, nightStyle], locationManager: locationManager, voiceController: routeVoice)
        if let coordinates = route.coordinates?.first {
            navigationController.mapView?.setCenter(coordinates, zoomLevel: 16, animated: false)
        }
        navigationController.mapView?.styleURL = self.styleURL
        navigationController.mapView?.logoView.image = nil // isHidden does nothing, so we set the image to nil
        navigationController.mapView?.logoView.isHidden = true
        navigationController.showsEndOfRouteFeedback = false // feedback view crashes the app on route completion
        navigationController.routeController.delegate = context.coordinator
        return navigationController
    }

    public func updateUIViewController(_ navigationViewController: MapboxNavigation.NavigationViewController, context _: Context) {
        navigationViewController.route = self.mapStore.routes?.routes.first
        CancelButton.appearance().setTitle("Finish", for: .normal)
        CancelButton.appearance().setImage(nil, for: .normal)
        CancelButton.appearance().textColor = .red
        print(#function)
    }

    public func makeCoordinator() -> NavigationViewCoordinator {
        NavigationViewCoordinator(parent: self)
    }
}
