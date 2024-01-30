//
//  MapView.swift
//  HudHud
//
//  Created by Patrick Kladek on 30.01.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI
import MapLibre

struct MapView: UIViewRepresentable {

	func makeUIView(context: Context) -> MLNMapView {
		// read the key from property list
		let mapTilerKey = getMapTilerkey()
		validateKey(mapTilerKey)

		// Build the style url
		let styleURL = URL(string: "https://api.maptiler.com/maps/streets-v2/style.json?key=\(mapTilerKey)")

		// create the mapview
		let mapView = MLNMapView(frame: .zero, styleURL: styleURL)
		mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		mapView.logoView.isHidden = true
		mapView.setCenter(
			CLLocationCoordinate2D(latitude: 47.127757, longitude: 8.579139),
			zoomLevel: 10,
			animated: false)

		// use the coordinator only if you need
		// to respond to the map events
		mapView.delegate = context.coordinator

		return mapView
	}

	func updateUIView(_ uiView: MGLMapView, context: Context) {}
}
