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

	let route: Route
	let styleURL: URL
	@ObservedObject var debugSettings: DebugSettings

	// MARK: - Lifecycle

	init(route: Route, styleURL: URL, debugSettings: DebugSettings) {
		self.route = route
		self.styleURL = styleURL
		self.debugSettings = debugSettings
	}

	// MARK: - Public

	public func makeUIViewController(context _: Context) -> MapboxNavigation.NavigationViewController {
		let simulatedLocationManager = SimulatedLocationManager(route: self.route)
		simulatedLocationManager.speedMultiplier = 1

		let locationManager = self.debugSettings.simulateRide ? simulatedLocationManager : nil

		let routeVoice = RouteVoiceController()
		let directions = Directions(accessToken: nil, host: debugSettings.routingURL)
		let navigationController = NavigationViewController(for: self.route, directions: directions, styles: [CustomDayStyle(), CustomNightStyle()], locationManager: locationManager, voiceController: routeVoice)
		navigationController.mapView?.styleURL = self.styleURL
		navigationController.mapView?.logoView.isHidden = true

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
