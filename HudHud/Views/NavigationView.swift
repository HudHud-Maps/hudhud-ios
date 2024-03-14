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
import SwiftUI
import ToursprungPOI

typealias JSONDictionary = [String: Any]

// MARK: - NavigationView

public struct NavigationView: UIViewControllerRepresentable {

	public typealias UIViewControllerType = NavigationViewController

	let route: Route
	let styleURL: URL

	// MARK: - Lifecycle

	init(route: Route, styleURL: URL) {
		self.route = route
		self.styleURL = styleURL
	}

	// MARK: - Public

	public func makeUIViewController(context _: Context) -> MapboxNavigation.NavigationViewController {
		let simulatedLocationManager = SimulatedLocationManager(route: self.route)
		simulatedLocationManager.speedMultiplier = 1

		let routeVoice = RouteVoiceController()

		let directions = Directions(accessToken: nil, host: "gh.maptoolkit.net")
		let navigationController = NavigationViewController(for: self.route, directions: directions, locationManager: simulatedLocationManager, voiceController: routeVoice)
		navigationController.mapView?.styleURL = self.styleURL

		return navigationController
	}

	public func updateUIViewController(_: MapboxNavigation.NavigationViewController, context _: Context) {
		print(#function)
	}

	public func makeCoordinator() -> NavigationViewCoordinator {
		NavigationViewCoordinator(parent: self)
	}
}
