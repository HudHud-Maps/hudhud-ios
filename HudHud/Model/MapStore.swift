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
	@Published var mapItemStatus: MapItemsStatus = .empty
	// since you are not using the selectedIndex, it may be better to not have a Struct called
	// MapItemsStatus at all and instead publish selectedMapItem and items in mapStore
	// directly - you will need to write code that ensures that if items are cleared,
	// selectedMapItem is too, etc...

	@Published var camera = MapViewCamera.center(.riyadh, zoom: 10)
	@Published var searchShown: Bool = true
}
