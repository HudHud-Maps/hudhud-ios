//
//  MapItemState.swift
//  HudHud
//
//  Created by Patrick Kladek on 22.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import POIService
import MapLibreSwiftUI
import MapLibre
import MapLibreSwiftDSL

struct MapItemsState {
	/// The index of the item from the mapItems that has been selected. The map will highlight this item and show details about it in a sheet.
	var selectedIndex: Int?

	/// The reports to show as pins on the map
	var mapItems: [Row]
	
	var points: ShapeSource {
		if let selectedIndex {
			return ShapeSource(identifier: "points") {
				let item = self.mapItems[selectedIndex]
				if let coordinate = item.coordinate {
					MLNPointFeature(coordinate: coordinate)
				}
			}
		}
		
		return ShapeSource(identifier: "points") {
			self.mapItems.compactMap { item in
				guard let coordinate = item.coordinate else { return nil }
				
				return MLNPointFeature(coordinate: coordinate)
			}
		}
	}
	
	var selectedItem: POI? {
		guard let selectedIndex else { return nil }
		
		return self.mapItems[selectedIndex].poi
	}

	init(selectedIndex: Int?, mapItems: [Row]) {
		// if only one item is returned we auto select it
		if mapItems.count == 1 {
			self.selectedIndex = 0
		} else {
			self.selectedIndex = selectedIndex
		}

		self.mapItems = mapItems
	}
}
