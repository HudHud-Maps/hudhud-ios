//
//  NavigationView.swift
//  HudHud
//
//  Created by Patrick Kladek on 01.03.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import MapboxNavigation
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import SwiftUI

public struct NavigationView: UIViewRepresentable {

	@Binding var camera: MapViewCamera

	let styleSource: MapStyleSource
	let userLayers: [StyleLayerDefinition]

	var gestures = [MapGesture]()
	var onStyleLoaded: ((MLNStyle) -> Void)?

	/// 'Escape hatch' to MLNMapView until we have more modifiers.
	/// See ``unsafeMapViewModifier(_:)``
	var unsafeMapViewModifier: ((MLNMapView) -> Void)?

	// MARK: - Lifecycle

	public init(
		styleURL: URL,
		camera: Binding<MapViewCamera> = .constant(.default()),
		@MapViewContentBuilder _ makeMapContent: () -> [StyleLayerDefinition] = { [] }
	) {
		self.styleSource = .url(styleURL)
		self._camera = camera
		self.userLayers = makeMapContent()
	}

	public init(
		styleURL: URL,
		constantCamera: MapViewCamera,
		@MapViewContentBuilder _ makeMapContent: () -> [StyleLayerDefinition] = { [] }
	) {
		self.init(styleURL: styleURL,
				  camera: .constant(constantCamera),
				  makeMapContent)
	}

	// MARK: - Public

	public func makeCoordinator() -> NavigationViewCoordinator {
		NavigationViewCoordinator(parent: self)
	}

	public func makeUIView(context: Context) -> NavigationMapView {
		// Create the map view
		let mapView = NavigationMapView(frame: .zero)
		mapView.navigationMapDelegate = context.coordinator
		context.coordinator.mapView = mapView

		switch self.styleSource {
		case let .url(styleURL):
			mapView.styleURL = styleURL
		}

//		context.coordinator.updateCamera(mapView: mapView,
//										 camera: self.$camera.wrappedValue,
//										 animated: false)

		// TODO: Make this settable via a modifier
		mapView.logoView.isHidden = true

		// Link the style loaded to the coordinator that emits the delegate event.
//		context.coordinator.onStyleLoaded = self.onStyleLoaded

		return mapView
	}

	public func updateUIView(_: MapboxNavigation.NavigationMapView, context: Context) {
		context.coordinator.parent = self

//		// MARK: Modifiers
//
//		self.unsafeMapViewModifier?(mapView)
//
//		// MARK: End Modifiers
//
//		// FIXME: This should be a more selective update
//		context.coordinator.updateStyleSource(self.styleSource, mapView: mapView)
//		context.coordinator.updateLayers(mapView: mapView)
//
//		// FIXME: This isn't exactly telling us if the *map* is loaded, and the docs for setCenter say it needs to be.
//		let isStyleLoaded = mapView.style != nil
//
//		context.coordinator.updateCamera(mapView: mapView,
//										 camera: self.$camera.wrappedValue,
//										 animated: isStyleLoaded)
	}
}

// #Preview {
//	NavigationView(styleURL: demoTilesURL)
//		.ignoresSafeArea(.all)
//		.previewDisplayName("Vanilla Map")
//
//	// For a larger selection of previews,
//	// check out the Examples directory, which
//	// has a wide variety of previews,
//	// organized into (hopefully) useful groups
// }
