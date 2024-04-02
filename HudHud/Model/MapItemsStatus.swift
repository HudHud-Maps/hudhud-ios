//
//  MapItemsStatus.swift
//  HudHud
//
//  Created by Patrick Kladek on 22.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import POIService
import SwiftUI

// MARK: - MapItemsStatus

final class MapItemsStatus: ObservableObject {

	@Published var selectedItem: POI?
	@Published var mapItems: [Row]
	@Published var streetViewPoint: StreetViewPoint?
	@NestedObservableObject var motionViewModel: MotionViewModel

	var points: ShapeSource {
		if let selectedItem, let locationCoordinate = selectedItem.locationCoordinate {
			return ShapeSource(identifier: "points") {
				MLNPointFeature(coordinate: locationCoordinate)
			}
		}
		return ShapeSource(identifier: "points") {
			self.mapItems.compactMap { item in
				guard let coordinate = item.coordinate else { return nil }

				return MLNPointFeature(coordinate: coordinate)
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

	init(selectedItem: POI? = nil, mapItems: [Row] = [], streetViewPoint: StreetViewPoint? = nil, motionViewModel: MotionViewModel) {
		self.selectedItem = selectedItem
		self.mapItems = mapItems
		self.streetViewPoint = streetViewPoint
		self.motionViewModel = motionViewModel
	}
}

extension MapItemsStatus {

	static var preview: MapItemsStatus {
		.init(motionViewModel: .init())
	}
}
