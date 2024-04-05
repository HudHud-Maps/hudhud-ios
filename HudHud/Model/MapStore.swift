//
//  MapStore.swift
//  HudHud
//
//  Created by Patrick Kladek on 23.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import POIService
import SwiftUI

// MARK: - MapStore

final class MapStore: ObservableObject {

	@ObservedObject var motionViewModel: MotionViewModel

	@Published var camera = MapViewCamera.center(.riyadh, zoom: 10)
	@Published var searchShown: Bool = true
	@Published var streetViewPoint: StreetViewPoint?

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

	var streetViewSource: ShapeSource {
		ShapeSource(identifier: "street-view-symbols") {
			if let streetViewPoint {
				let streetViewPoint = StreetViewPoint(location: streetViewPoint.location,
													  heading: self.motionViewModel.position.heading)
				streetViewPoint.feature
			}
		}
	}

	// MARK: - Lifecycle

	init(camera: MapViewCamera = MapViewCamera.center(.riyadh, zoom: 10), searchShown: Bool = true, streetViewPoint: StreetViewPoint? = nil, motionViewModel: MotionViewModel) {
		self.camera = camera
		self.searchShown = searchShown
		self.streetViewPoint = streetViewPoint
		self.motionViewModel = motionViewModel
	}
}

// MARK: - Preview

extension MapStore: Preview {

	static let preview = MapStore(motionViewModel: MotionViewModel())
}

// MARK: - Private

private extension MapStore {

	func updateCameraForMapItems() {
		let coordinates = self.mapItems.compactMap(\.coordinate)
		guard let camera = CameraState.boundingBox(from: coordinates) else { return }

		self.camera = camera
	}
}
