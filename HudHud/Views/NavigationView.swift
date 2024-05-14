//
//  NavigationView.swift
//  HudHud
//
//  Created by Patrick Kladek on 01.03.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import MapboxCoreNavigation
import MapboxDirections
import MapboxNavigation
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import POIService
import SwiftUI

typealias JSONDictionary = [String: Any]

// MARK: - NavigationView

public struct NavigationView: UIViewControllerRepresentable {

	public typealias UIViewControllerType = NavigationViewController

	let route: Route?
	let styleURL: URL

	// MARK: - Lifecycle

	init(route: Route?, styleURL: URL) {
		self.route = route
		self.styleURL = styleURL
	}

	// MARK: - Public

	public func makeUIViewController(context _: Context) -> MapboxNavigation.NavigationViewController {
		var simulatedLocationManager: SimulatedLocationManager?

		if let route = self.route {
			simulatedLocationManager = SimulatedLocationManager(route: route)
			simulatedLocationManager?.speedMultiplier = 2
		}

		let routeVoice = RouteVoiceController()
		let directions = Directions(accessToken: nil, host: "gh.maptoolkit.net")
		let navigationController = NavigationViewController(for: self.route, directions: directions, styles: [CustomDayStyle(), CustomNightStyle()], locationManager: simulatedLocationManager, voiceController: routeVoice)
		navigationController.mapView?.styleURL = self.styleURL
		navigationController.mapView?.logoView.isHidden = true
		navigationController.mapView?.allowsTilting = false
		navigationController.mapView?.userTrackingMode = .follow
		navigationController.mapView?.showsUserLocation = true

		let location = CLLocation(coordinate: .riyadh,
								  altitude: 1000,
								  horizontalAccuracy: 10,
								  verticalAccuracy: 10,
								  timestamp: .now)

		navigationController.mapView?.updateCourseTracking(location: location)
		navigationController.mapView?.camera.centerCoordinate = .riyadh

		return navigationController
	}

	public func updateUIViewController(_: MapboxNavigation.NavigationViewController, context _: Context) {
		CancelButton.appearance().setTitle("Finish", for: .normal)
		CancelButton.appearance().setImage(nil, for: .normal)
		CancelButton.appearance().textColor = .red
		print(#function)
	}

	public func makeCoordinator() -> NavigationViewCoordinator {
		NavigationViewCoordinator(parent: self)
	}
}
