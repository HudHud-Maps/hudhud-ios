//
//  MapStore.swift
//  HudHud
//
//  Created by Patrick Kladek on 23.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Combine
import CoreLocation
import Foundation
import MapLibre
import MapLibreSwiftUI
import SwiftUI

// MARK: - MapStore

final class MapStore: ObservableObject {

	private var cancelable: [AnyCancellable] = []

	@NestedObservableObject var mapItemStatus: MapItemsStatus {
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

	// MARK: - Lifecycle

	init(mapItemStatus: MapItemsStatus, camera: MapViewCamera = MapViewCamera.center(.riyadh, zoom: 10), searchShown: Bool = true) {
		self.mapItemStatus = mapItemStatus
		self.camera = camera
		self.searchShown = searchShown

		self.mapItemStatus.$selectedItem.sink { item in
			guard let coordinate = item?.locationCoordinate else { return }

			self.camera = .center(coordinate, zoom: 16)
		}.store(in: &self.cancelable)

		self.mapItemStatus.$mapItems.sink { mapItems in
			let coordinates = mapItems.compactMap(\.coordinate)
			guard let camera = CameraState.boundingBox(from: coordinates) else { return }

			self.camera = camera
		}.store(in: &self.cancelable)
	}
}
