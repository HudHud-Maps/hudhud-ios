//
//  MapView.swift
//  HudHud
//
//  Created by Patrick Kladek on 30.01.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import MapLibre
import SwiftUI

struct MapView: UIViewRepresentable {

	func makeUIView(context: Context) -> MLNMapView {
		// Build the style url
		let styleURL = Bundle.main.url(forResource: "Terrain", withExtension: "json")

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

	func updateUIView(_ uiView: MLNMapView, context: Context) {}

	func makeCoordinator() -> MapView.Coordinator {
		Coordinator(self)
	}
}

extension MapView {

	class Coordinator: NSObject, MLNMapViewDelegate {
		var control: MapView

		init(_ control: MapView) {
			self.control = control
		}

		func mapViewDidFinishLoadingMap(_ mapView: MLNMapView) {
			// write your custom code which will be executed
			// after map has been loaded
		}
	}
}

#Preview {
	MapView()
}
