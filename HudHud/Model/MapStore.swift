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
import ToursprungPOI

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

	@Published var selectedItem: POI? {
		didSet {
			if let coordinate = self.selectedItem?.locationCoordinate {
				self.camera = .center(coordinate, zoom: 16)
			} else if self.mapItems.isEmpty == false {
				self.updateCameraForMapItems()
			}
		}
	}

	@Published var mapItems: [Row] = [] {
		didSet {
			self.updateCameraForMapItems()
		}
	}

	var points: ShapeSource {
		return ShapeSource(identifier: "points") {
			self.mapItems.compactMap { item in
				guard let coordinate = item.coordinate else { return nil }

				return MLNPointFeature(coordinate: coordinate) { feature in
					if let poi = item.poi {
						feature.attributes["poi_id"] = poi.id
					}
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
				case let .poi(poi):
					if let poiCoordinate = poi.locationCoordinate {
						let feature = MLNPointFeature(coordinate: poiCoordinate)
						feature.attributes["poi_id"] = poi.id
						features.append(feature)
					}
				}
			}
		}
		return ShapeSource(identifier: "routePoints") {
			features
		}
	}

	var streetViewSource: ShapeSource {
		ShapeSource(identifier: "street-view-symbols") {
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
		let coordinates = self.mapItems.compactMap(\.coordinate)
		guard let camera = CameraState.boundingBox(from: coordinates) else { return }

		self.camera = camera
	}
}
