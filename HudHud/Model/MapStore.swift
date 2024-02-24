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

struct MapStore {

	@State var mapItemStore: MapItemsStore
	@State var camera = MapViewCamera.center(.riyadh, zoom: 10)
	@State var selectedDetent: PresentationDetent = .small
	@State var searchShown: Bool = true

}
