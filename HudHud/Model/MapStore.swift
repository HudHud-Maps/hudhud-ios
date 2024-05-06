//
//  MapStore.swift
//  HudHud
//
//  Created by Patrick Kladek on 23.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation
import MapboxDirections
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import POIService
import SwiftUI

// MARK: - MapStore

final class MapStore: ObservableObject {

	enum StreetViewOption: Equatable {
		case disabled
		case requestedCurrentLocation
		case enabled
	}

	let motionViewModel: MotionViewModel

	@Published var camera = MapViewCamera.center(.riyadh, zoom: 10)
	@Published var searchShown: Bool = true
	@Published var streetView: StreetViewOption = .disabled
	@Published var routes: Toursprung.RouteCalculationResult?
	@Published var waypoints: [ABCRouteConfigurationItem]?

	@Published var displayableItems: [AnyDisplayableAsRow] = []

	@Published var selectedItem: ResolvedItem? {
		didSet {
			if let selectedItem {
				self.addToRecents(selectedItem)
			}
		}
	}

	var mapItems: [ResolvedItem] {
		self.displayableItems.compactMap { $0.innerModel as? ResolvedItem }
	}

	var points: ShapeSource {
		return ShapeSource(identifier: MapSourceIdentifier.points, options: [.clustered: true, .clusterRadius: 44]) {
			self.mapItems.compactMap { item in
				return MLNPointFeature(coordinate: item.coordinate) { feature in
					feature.attributes["poi_id"] = item.id
				}
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

	var streetViewSource: ShapeSource {
		ShapeSource(identifier: MapSourceIdentifier.streetViewSymbols) {
			if case .enabled = self.streetView, let coordinate = self.motionViewModel.coordinate {
				let streetViewPoint = StreetViewPoint(location: coordinate,
													  heading: self.motionViewModel.position.heading)
				streetViewPoint.feature
			}
		}
	}

	// MARK: - Lifecycle

	init(camera: MapViewCamera = MapViewCamera.center(.riyadh, zoom: 10), searchShown: Bool = true, motionViewModel: MotionViewModel) {
		self.camera = camera
		self.searchShown = searchShown
		self.motionViewModel = motionViewModel
	}
}

// MARK: - Previewable

extension MapStore: Previewable {

	static let storeSetUpForPreviewing = MapStore(motionViewModel: .storeSetUpForPreviewing)
}

// MARK: - Private

private extension MapStore {

	func updateCameraForMapItems() {
		let coordinates = self.mapItems.map(\.coordinate)
		guard let camera = CameraState.boundingBox(from: coordinates) else { return }

		self.camera = camera
	}

	func addToRecents(_: ResolvedItem) {
//		withAnimation {
//			if self.recentViewedPOIs.count > 9 {
//				self.recentViewedPOIs.removeFirst()
//			}
//			if !self.recentViewedPOIs.contains(poi) {
//				self.recentViewedPOIs.append(poi)
//			}
//		}
	}
}
