//
//  PortraitNavigationView.swift
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

// MARK: - PortraitNavigationView

/// A portrait orientation navigation view that includes the InstructionsView at the top.
public struct PortraitNavigationView<T: MapViewHostViewController>: View, CustomizableNavigatingInnerGridView, SpeedLimitViewHost {

    // MARK: Properties

    public var speedLimit: Measurement<UnitSpeed>?

    public var topCenter: (() -> AnyView)?
    public var topTrailing: (() -> AnyView)?
    public var midLeading: (() -> AnyView)?
    public var bottomTrailing: (() -> AnyView)?
    public var bottomLeading: (() -> AnyView)?

    public var minimumSafeAreaInsets: EdgeInsets

    @Environment(\.navigationFormatterCollection) var formatterCollection: any FormatterCollection

    let styleURL: URL
    @Binding var camera: MapViewCamera
    let navigationCamera: MapViewCamera
    let makeViewController: () -> T

    let isMuted: Bool
    let onTapMute: () -> Void
    var onTapExit: (() -> Void)?

    private var navigationState: NavigationState?
    private let userLayers: [StyleLayerDefinition]
    private let locationManager: HudHudLocationManager

    // MARK: Lifecycle

    /// Create a portrait navigation view. This view is optimized for display on a portrait screen where the
    /// instructions and arrival view are on the top and bottom of the screen.
    /// The user puck and route are optimized for the center of the screen.
    ///
    /// - Parameters:
    ///   - styleURL: The map's style url.
    ///   - camera: The camera binding that represents the current camera on the map.
    ///   - navigationCamera: The default navigation camera. This sets the initial camera & is also used when the center
    ///                       on user button it tapped.
    ///   - navigationState: The current ferrostar navigation state provided by the Ferrostar core.
    ///   - minimumSafeAreaInsets: The minimum padding to apply from safe edges. See `complementSafeAreaInsets`.
    ///   - onTapExit: An optional behavior to run when the ArrivalView exit button is tapped. When nil (default) the
    ///             exit button is hidden.
    ///   - makeMapContent: Custom maplibre symbols to display on the map view.
    public init(
        makeViewController: @autoclosure @escaping () -> T,
        locationManager: HudHudLocationManager,
        styleURL: URL,
        camera: Binding<MapViewCamera>,
        navigationCamera: MapViewCamera = .automotiveNavigation(),
        navigationState: NavigationState?,
        isMuted: Bool,
        minimumSafeAreaInsets: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        onTapMute: @escaping () -> Void,
        onTapExit: (() -> Void)? = nil,
        @MapViewContentBuilder makeMapContent: () -> [StyleLayerDefinition] = { [] }
    ) {
        self.makeViewController = makeViewController
        self.locationManager = locationManager
        self.styleURL = styleURL
        self._camera = camera
        self.navigationCamera = navigationCamera
        self.navigationState = navigationState
        self.isMuted = isMuted
        self.minimumSafeAreaInsets = minimumSafeAreaInsets
        self.onTapMute = onTapMute
        self.onTapExit = onTapExit

        self.userLayers = makeMapContent()
    }

    // MARK: Content

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                NavigationMapView(
                    makeViewController: self.makeViewController(),
                    locationManager: self.locationManager,
                    styleURL: self.styleURL,
                    camera: self.$camera,
                    navigationState: self.navigationState,
                    onStyleLoaded: { _ in
                        self.camera = self.navigationCamera
                    }, makeMapContent: {
                        self.userLayers
                    }
                )
                .navigationMapViewContentInset(.portrait(within: geometry))

                PortraitNavigationOverlayView(
                    navigationState: self.navigationState,
                    speedLimit: self.speedLimit,
                    isMuted: self.isMuted,
                    showMute: true,
                    onMute: self.onTapMute,
                    showZoom: true,
                    onZoomIn: { self.camera.incrementZoom(by: 1) },
                    onZoomOut: { self.camera.incrementZoom(by: -1) },
                    showCentering: !self.camera.isTrackingUserLocationWithCourse,
                    onCenter: { self.camera = self.navigationCamera },
                    onTapExit: self.onTapExit
                )
                .innerGrid {
                    self.topCenter?()
                } topTrailing: {
                    self.topTrailing?()
                } midLeading: {
                    self.midLeading?()
                } bottomTrailing: {
                    self.bottomTrailing?()
                } bottomLeading: {
                    self.bottomLeading?()
                }.complementSafeAreaInsets(parentGeometry: geometry, minimumInsets: self.minimumSafeAreaInsets)
            }
        }
    }
}

public extension PortraitNavigationView where T == MLNMapViewController {
    /// Create a portrait navigation view. This view is optimized for display on a portrait screen where the
    /// instructions and arrival view are on the top and bottom of the screen.
    /// The user puck and route are optimized for the center of the screen.
    ///
    /// - Parameters:
    ///   - styleURL: The map's style url.
    ///   - camera: The camera binding that represents the current camera on the map.
    ///   - navigationCamera: The default navigation camera. This sets the initial camera & is also used when the center
    /// on user button it tapped.
    ///   - navigationState: The current ferrostar navigation state provided by the Ferrostar core.
    ///   - minimumSafeAreaInsets: The minimum padding to apply from safe edges. See `complementSafeAreaInsets`.
    ///   - onTapExit: An optional behavior to run when the ArrivalView exit button is tapped. When nil (default) the
    /// exit button is hidden.
    ///   - makeMapContent: Custom maplibre symbols to display on the map view.
    init(
        styleURL: URL,
        camera: Binding<MapViewCamera>,
        locationManager: HudHudLocationManager,
        navigationCamera: MapViewCamera = .automotiveNavigation(),
        navigationState: NavigationState?,
        minimumSafeAreaInsets: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        isMuted: Bool,
        onTapMute: @escaping () -> Void,
        onTapExit: (() -> Void)? = nil,
        @MapViewContentBuilder makeMapContent: () -> [StyleLayerDefinition] = { [] }
    ) {
        self.makeViewController = MLNMapViewController.init
        self.locationManager = locationManager
        self.styleURL = styleURL
        self.navigationState = navigationState
        self.minimumSafeAreaInsets = minimumSafeAreaInsets
        self.onTapExit = onTapExit
        self.onTapMute = onTapMute
        self.isMuted = isMuted
        self.userLayers = makeMapContent()
        _camera = camera
        self.navigationCamera = navigationCamera
    }
}
