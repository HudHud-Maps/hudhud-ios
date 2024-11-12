//
//  NavigationMapView.swift
//  HudHud
//
//  Created by Ali Hilal on 03.11.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import FerrostarCore
import MapKit
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import SwiftUI

// MARK: - NavigationMapView

/// The most generic map view in Ferrostar.
///
/// This view includes renders a route line and includes a default camera.
/// It does not include other UI elements like instruction banners.
/// This is the basis of higher level views like
/// ``DynamicallyOrientingNavigationView``.
public struct NavigationMapView<T: MapViewHostViewController>: View {

    // MARK: Properties

    let makeViewController: () -> T
    let styleURL: URL
    var mapViewContentInset: UIEdgeInsets = .zero
    var onStyleLoaded: (MLNStyle) -> Void
    let userLayers: [StyleLayerDefinition]
    let mapViewModifiers: (_ view: MapView<T>, _ isNavigating: Bool) -> MapView<T>

    // MARK: Camera Settings

    @Binding var camera: MapViewCamera

    private var isNavigating: Bool

    private var locationManager: PassthroughLocationManager

    // MARK: Computed Properties

    private var effectiveMapViewContentInset: UIEdgeInsets {
        return self.isNavigating == true ? self.mapViewContentInset : .zero
    }

    // MARK: Lifecycle

    /// Initialize a map view tuned for turn by turn navigation.
    ///
    /// - Parameters:
    ///   - styleURL: The map's style url.
    ///   - camera: The camera binding that represents the current camera on the map.
    ///   - navigationState: The current ferrostar navigation state provided by ferrostar core.
    ///   - onStyleLoaded: The map's style has loaded and the camera can be manipulated (e.g. to user tracking).
    ///   - makeMapContent: Custom maplibre symbols to display on the map view.
    public init(makeViewController: @autoclosure @escaping () -> T,
                locationManager: PassthroughLocationManager,
                styleURL: URL,
                camera: Binding<MapViewCamera>,
                isNavigating: Bool,
                onStyleLoaded: @escaping ((MLNStyle) -> Void),
                @MapViewContentBuilder makeMapContent: () -> [StyleLayerDefinition] = { [] },
                mapViewModifiers: @escaping (_ view: MapView<T>, _ isNavigating: Bool) -> MapView<T> = { transferView, _ in
                    transferView
                }) {
        self.makeViewController = makeViewController
        self.locationManager = locationManager
        self.styleURL = styleURL
        _camera = camera
        self.isNavigating = isNavigating
        self.onStyleLoaded = onStyleLoaded
        self.userLayers = makeMapContent()
        self.mapViewModifiers = mapViewModifiers
    }

    // MARK: Content

    public var body: some View {
        MapView(makeViewController: self.makeViewController(),
                styleURL: self.styleURL,
                camera: self.$camera,
                locationManager: self.locationManager) {
            self.userLayers
        }

        .mapViewContentInset(self.effectiveMapViewContentInset)
        .mapControls {
            // No controls
        }
        .onStyleLoaded(self.onStyleLoaded)
        .applyTransform(transform: self.mapViewModifiers, isNavigating: self.isNavigating)
        .padding(.bottom, self.isNavigating ? 120 : 0) // Add padding only during navigation
        .ignoresSafeArea(.all)
    }
}

extension MapView {

    @ViewBuilder
    func applyTransform(transform: (Self, Bool) -> some View, isNavigating: Bool) -> some View {
        transform(self, isNavigating)
    }
}
