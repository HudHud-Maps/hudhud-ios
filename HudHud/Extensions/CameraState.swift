//
//  CameraState.swift
//  HudHud
//
//  Created by Patrick Kladek on 02.04.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import MapLibre
import MapLibreSwiftUI

extension CameraState {

	static func boundingBox(from locations: [CLLocationCoordinate2D], edgePadding: UIEdgeInsets) -> MapViewCamera? {
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
		return .boundingBox(coordinateBounds, edgePadding: edgePadding)
	}
}
