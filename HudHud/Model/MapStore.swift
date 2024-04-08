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
import MapLibreSwiftUI
import SwiftUI

// MARK: - MapStore

class MapStore: ObservableObject {

	@MainActor
	@Published var mapItemStatus: MapItemsStatus = .empty {
		didSet {
			if let coordinate = self.mapItemStatus.selectedItem?.locationCoordinate {
				self.camera = .center(coordinate, zoom: 16)
				return
			}

			let coordinates = self.mapItemStatus.mapItems.compactMap(\.coordinate)
			if let camera = CameraState.boundingBox(from: coordinates) {
				self.camera = camera
			}
		}
	}

	@Published var camera = MapViewCamera.center(.riyadh, zoom: 10)
	@Published var searchShown: Bool = true
}

extension CameraState {

	static func boundingBox(from locations: [CLLocationCoordinate2D]) -> MapViewCamera? {
		guard !locations.isEmpty else { return nil }

		var minLat = locations[0].latitude
		var maxLat = locations[0].latitude
		var minLon = locations[0].longitude
		var maxLon = locations[0].longitude

		for coordinate in locations {
			minLat = min(minLat, coordinate.latitude)
			maxLat = max(maxLat, coordinate.latitude)
			minLon = min(minLon, coordinate.longitude)
			maxLon = max(maxLon, coordinate.longitude)
		}

		let northeast = CLLocationCoordinate2D(latitude: maxLat, longitude: maxLon)
		let southwest = CLLocationCoordinate2D(latitude: minLat, longitude: minLon)
		let coordinateBounds = MLNCoordinateBounds(sw: southwest, ne: northeast)
		return .boundingBox(coordinateBounds)
	}

	static func centerOfCoordinates(from coordinates: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D? {
		guard !coordinates.isEmpty else { return nil }

		var totalLatitude: CLLocationDegrees = 0
		var totalLongitude: CLLocationDegrees = 0

		for coordinate in coordinates {
			totalLatitude += coordinate.latitude
			totalLongitude += coordinate.longitude
		}

		let averageLatitude = totalLatitude / Double(coordinates.count)
		let averageLongitude = totalLongitude / Double(coordinates.count)

		return CLLocationCoordinate2D(latitude: averageLatitude, longitude: averageLongitude)
	}

}
