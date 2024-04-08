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
import MapLibreSwiftDSL
import MapLibreSwiftUI
import POIService
import SwiftUI

// MARK: - MapStore

final class MapStore: ObservableObject {

	enum StreetViewOption: Equatable {
		case disabled
		case requestedCurrentLocation
		case point(StreetViewPoint)
	}

	let motionViewModel: MotionViewModel

	@Binding var sheetSize: CGSize
	@Published var camera = MapViewCamera.center(.riyadh, zoom: 10)
	@Published var searchShown: Bool = true
	@Published var streetView: StreetViewOption = .disabled

	@Published var selectedItem: POI? {
		didSet {
			if let coordinate = self.selectedItem?.locationCoordinate {
				self.camera = .center(coordinate, zoom: 16)
			} else if self.mapItems.isEmpty == false {
				self.updateCameraForMapItems()
			}
		}
	}

	@Published var mapItems: [Row] = [] {
		didSet {
			self.updateCameraForMapItems()
		}
	}

	var points: ShapeSource {
		return ShapeSource(identifier: "points") {
			self.mapItems.compactMap { item in
				guard let coordinate = item.coordinate else { return nil }

				return MLNPointFeature(coordinate: coordinate) { feature in
					if let poi = item.poi {
						feature.attributes["poi_id"] = poi.id
					}
				}
			}
		}
	}

	var streetViewSource: ShapeSource {
		ShapeSource(identifier: "street-view-symbols") {
			if case let .point(point) = streetView {
				let streetViewPoint = StreetViewPoint(location: point.location,
													  heading: self.motionViewModel.position.heading)
				streetViewPoint.feature
			}
		}
	}

	// MARK: - Lifecycle

	init(camera: MapViewCamera = MapViewCamera.center(.riyadh, zoom: 10), searchShown: Bool = true, streetViewPoint: StreetViewPoint? = nil, motionViewModel: MotionViewModel, sheetSize: Binding<CGSize>) {
		self.camera = camera
		self.searchShown = searchShown
		self.motionViewModel = motionViewModel

		if let streetViewPoint {
			self.streetView = .point(streetViewPoint)
		} else {
			self.streetView = .disabled
		}
		self._sheetSize = sheetSize
	}

	// MARK: - Internal

	func bind(sheetSize: Binding<CGSize>) {
		self._sheetSize = sheetSize
	}
}

// MARK: - Previewable

extension MapStore: Previewable {

	static let preview = MapStore(motionViewModel: .preview, sheetSize: .constant(.zero))
}

// MARK: - Private

private extension MapStore {

	func updateCameraForMapItems() {
		let coordinates = self.mapItems.compactMap(\.coordinate)
		let edgePadding = UIEdgeInsets(top: 0, left: 0, bottom: 400, right: 0)

		guard let camera = CameraState.boundingBox(from: coordinates, edgePadding: edgePadding) else { return }

		self.camera = camera
	}
}
