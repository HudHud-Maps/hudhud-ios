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
public struct PortraitNavigationView<T: MapViewHostViewController>: View, CustomizableNavigatingInnerGridView, SpeedLimitViewHost, NavigationOverlayContent {

    // MARK: Properties

    public var speedLimit: Measurement<UnitSpeed>?

    public var topCenter: (() -> AnyView)?
    public var topTrailing: (() -> AnyView)?
    public var midLeading: (() -> AnyView)?
    public var bottomTrailing: (() -> AnyView)?
    public var bottomLeading: (() -> AnyView)?

    public var minimumSafeAreaInsets: EdgeInsets

    public var overlayStore: OverlayContentStore

    @Environment(\.navigationFormatterCollection) var formatterCollection: any FormatterCollection

    let styleURL: URL
    @Binding var camera: MapViewCamera
    let navigationCamera: MapViewCamera
    let makeViewController: () -> T

    let isMuted: Bool
    let onTapMute: () -> Void
    var onTapExit: (() -> Void)?

    let isNavigating: Bool

    // TODO: Configurable camera and user "puck" rotation modes

    private var navigationState: NavigationState?
    private let userLayers: [StyleLayerDefinition]
    private let locationManager: PassthroughLocationManager

    // MARK: Lifecycle

    public init(
        makeViewController: @autoclosure @escaping () -> T,
        overlayStore: OverlayContentStore,
        locationManager: PassthroughLocationManager,
        styleURL: URL,
        camera: Binding<MapViewCamera>,
        navigationCamera: MapViewCamera = .automotiveNavigation(),
        isNavigating: Bool,
        isMuted: Bool,
        minimumSafeAreaInsets: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        onTapMute: @escaping () -> Void,
        onTapExit: (() -> Void)? = nil,
        @MapViewContentBuilder makeMapContent: () -> [StyleLayerDefinition] = { [] }
    ) {
        self.makeViewController = makeViewController
        self.overlayStore = overlayStore
        self.locationManager = locationManager
        self.styleURL = styleURL
        self._camera = camera
        self.navigationCamera = navigationCamera
        self.isNavigating = isNavigating
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
                    isNavigating: self.isNavigating,
                    onStyleLoaded: { _ in
                        self.camera = self.navigationCamera
                    }, makeMapContent: {
                        self.userLayers
                    }
                )
                .navigationMapViewContentInset(.portrait(within: geometry))

                PortraitNavigationOverlayView(
                    overlayStore: self.overlayStore,
                    speedLimit: self.speedLimit,
                    isMuted: self.isMuted,
                    showMute: true,
                    onMute: self.onTapMute,
                    showZoom: true,
                    onZoomIn: { self.camera.incrementZoom(by: 1) },
                    onZoomOut: { self.camera.incrementZoom(by: -1) },
                    showCentering: !self.camera.isTrackingUserLocationWithCourse,
                    onCenter: { self.camera = self.navigationCamera }
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
