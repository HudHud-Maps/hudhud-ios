//
//  MapItemState.swift
//  HudHud
//
//  Created by Patrick Kladek on 22.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import POIService

struct MapItemsState {
	/// The index of the item from the mapItems that has been selected. The map will highlight this item and show details about it in a sheet.
	let selectedIndex: Int?

	/// The reports to show as pins on the map
	let mapItems: [POI]?

	init(selectedIndex: Int?, mapItems: [POI]?) {
		// if only one item is returned we auto select it
		if mapItems?.count == 1 {
			self.selectedIndex = 0
		} else {
			self.selectedIndex = selectedIndex
		}

		self.mapItems = mapItems
	}
}
