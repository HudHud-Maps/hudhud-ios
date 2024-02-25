//
//  MapStore.swift
//  HudHud
//
//  Created by Patrick Kladek on 23.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import MapLibreSwiftUI
import SwiftUI

// Anything called "Store" will always be a class and an ObservableObject
class MapStore: ObservableObject {

	// @Binding and @State is only used in a View, @Published is the only thing you use in ObservableObject
	@MainActor
	@Published var mapItemStatus: MapItemsStatus = .empty {
		didSet {
			if let coordinate = self.mapItemStatus.selectedItem?.locationCoordinate {
				self.camera = .center(coordinate, zoom: 16)
			}
		}
	}

	@Published var camera = MapViewCamera.center(.riyadh, zoom: 10)
	@Published var searchShown: Bool = true
}
