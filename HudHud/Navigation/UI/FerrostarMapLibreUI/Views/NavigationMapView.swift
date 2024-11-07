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

    private var navigationState: NavigationState?
    private var locationManager: HudHudLocationManager

    // MARK: Computed Properties

    private var effectiveMapViewContentInset: UIEdgeInsets {
        return self.navigationState?.isNavigating == true ? self.mapViewContentInset : .zero
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
    public init(
        makeViewController: @autoclosure @escaping () -> T,
        locationManager: HudHudLocationManager,
        styleURL: URL,
        camera: Binding<MapViewCamera>,
        navigationState: NavigationState?,
        onStyleLoaded: @escaping ((MLNStyle) -> Void),
        @MapViewContentBuilder makeMapContent: () -> [StyleLayerDefinition] = { [] },
        mapViewModifiers: @escaping (_ view: MapView<T>, _ isNavigating: Bool) -> MapView<T> = { transferView, _ in
            transferView
        }
    ) {
        self.makeViewController = makeViewController
        self.locationManager = locationManager
        self.styleURL = styleURL
        _camera = camera
        self.navigationState = navigationState
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
            if let routePolyline = navigationState?.routePolyline {
                RouteStyleLayer(polyline: routePolyline,
                                identifier: "route-polyline",
                                style: TravelledRouteStyle())
            }

            if let remainingRoutePolyline = navigationState?.remainingRoutePolyline {
                RouteStyleLayer(polyline: remainingRoutePolyline,
                                identifier: "remaining-route-polyline")
            }

            self.updateCameraIfNeeded()

            // Overlay any additional user layers.
            self.userLayers
        }
        .mapViewContentInset(self.effectiveMapViewContentInset)
        .mapControls {
            // No controls
        }
        .onStyleLoaded(self.onStyleLoaded)
        .applyTransform(transform: self.mapViewModifiers, isNavigating: self.navigationState?.isNavigating == true)
        .ignoresSafeArea(.all)
    }

    // MARK: Functions

    private func updateCameraIfNeeded() {
        if case let .navigating(_, snappedUserLocation: userLocation, _, _, _, _, _, _, _) = navigationState?.tripState,
           // There is no reason to push an update if the coordinate and heading are the same.
           // That's all that gets displayed, so it's all that MapLibre should care about.
           locationManager.lastLocation?.coordinate != userLocation.coordinates
               .clLocationCoordinate2D || locationManager.lastLocation?.course != userLocation.clLocation.course {
            self.locationManager.useSnappedLocation(userLocation.clLocation)
        } else {
            self.locationManager.useRawLocation()
        }
    }
}

extension MapView {
    @ViewBuilder
    func applyTransform(
        transform: (Self, Bool) -> some View, isNavigating: Bool
    ) -> some View {
        transform(self, isNavigating)
    }
}

public extension NavigationMapView where T == MLNMapViewController {
    /// Initialize a map view tuned for turn by turn navigation.
    ///
    /// - Parameters:
    ///   - styleURL: The map's style url.
    ///   - camera: The camera binding that represents the current camera on the map.
    ///   - navigationState: The current ferrostar navigation state provided by ferrostar core.
    ///   - onStyleLoaded: The map's style has loaded and the camera can be manipulated (e.g. to user tracking).
    ///   - makeMapContent: Custom maplibre symbols to display on the map view.
    init(
        styleURL: URL,
        locationManager: HudHudLocationManager,
        camera: Binding<MapViewCamera>,
        navigationState: NavigationState?,
        onStyleLoaded: @escaping ((MLNStyle) -> Void),
        @MapViewContentBuilder _ makeMapContent: () -> [StyleLayerDefinition] = { [] },
        mapViewModifiers: @escaping (_ view: MapView<T>, _ isNavigating: Bool) -> MapView<T> = { transferView, _ in
            transferView
        }
    ) {
        self.makeViewController = MLNMapViewController.init
        self.locationManager = locationManager
        self.styleURL = styleURL
        _camera = camera
        self.navigationState = navigationState
        self.onStyleLoaded = onStyleLoaded
        self.userLayers = makeMapContent()
        self.mapViewModifiers = mapViewModifiers
    }
}
