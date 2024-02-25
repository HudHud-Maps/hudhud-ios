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

// MARK: - MapItemsStore

// Anything that is not an ObservableObject is not a Store - I'd usually call this "State" but as this might confuse people for something to do with @State I'm calling it Status here.
struct MapItemsStatus {

	var selectedItem: POI?
	var mapItems: [Row]

	var points: ShapeSource {
		if let selectedItem {
			return ShapeSource(identifier: "points") {
				MLNPointFeature(coordinate: selectedItem.locationCoordinate)
			}
		}

		return ShapeSource(identifier: "points") {
			self.mapItems.compactMap { item in
				guard let coordinate = item.coordinate else { return nil }

				return MLNPointFeature(coordinate: coordinate)
			}
		}
	}

	static var empty: MapItemsStatus {
		.init(selectedItem: nil, mapItems: [])
	}

	// MARK: - Lifecycle

	init(selectedItem: POI?, mapItems: [Row]) {
		self.selectedItem = selectedItem
		self.mapItems = mapItems
	}
}
