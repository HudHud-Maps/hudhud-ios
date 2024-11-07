//
//  LandscapeNavigationOverlayView.swift
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

struct LandscapeNavigationOverlayView: View, CustomizableNavigatingInnerGridView, NavigationOverlayContent {

    // MARK: Properties

    var topCenter: (() -> AnyView)?
    var topTrailing: (() -> AnyView)?
    var midLeading: (() -> AnyView)?
    var bottomTrailing: (() -> AnyView)?
    var bottomLeading: (() -> AnyView)?

    var speedLimit: Measurement<UnitSpeed>?

    var showZoom: Bool
    var onZoomIn: () -> Void
    var onZoomOut: () -> Void

    var showCentering: Bool
    var onCenter: () -> Void

    let showMute: Bool
    let isMuted: Bool
    let onMute: () -> Void

    var overlayStore: OverlayContentStore

    // MARK: Lifecycle

    init(
        overlayStore: OverlayContentStore,
        speedLimit: Measurement<UnitSpeed>? = nil,
        isMuted: Bool,
        showMute: Bool = true,
        onMute: @escaping () -> Void,
        showZoom: Bool = false,
        onZoomIn: @escaping () -> Void = {},
        onZoomOut: @escaping () -> Void = {},
        showCentering: Bool = false,
        onCenter: @escaping () -> Void = {}
    ) {
        self.overlayStore = overlayStore
        self.speedLimit = speedLimit
        self.isMuted = isMuted
        self.onMute = onMute
        self.showMute = showMute
        self.showZoom = showZoom
        self.onZoomIn = onZoomIn
        self.onZoomOut = onZoomOut
        self.showCentering = showCentering
        self.onCenter = onCenter
    }

    // MARK: Content

    var body: some View {
        HStack {
            ZStack(alignment: .top) {
                VStack {
                    Spacer()
                    if let progressView = overlayStore.content[.tripProgress] {
                        progressView()
                    }
                }

                if let instrcutionsView = overlayStore.content[.instructions] {
                    instrcutionsView()
                }
            }

            Spacer().frame(width: 16)

            // The inner content is displayed vertically full screen
            // when both the visualInstructions and progress are nil.
            // It will automatically reduce height if and when either
            // view appears
            NavigatingInnerGridView(
                speedLimit: self.speedLimit,
                isMuted: self.isMuted,
                showMute: self.showMute,
                onMute: self.onMute,
                showZoom: self.showZoom,
                onZoomIn: self.onZoomIn,
                onZoomOut: self.onZoomOut,
                showCentering: self.showCentering,
                onCenter: self.onCenter
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
            }
        }
    }
}
