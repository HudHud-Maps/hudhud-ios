import FerrostarCore
import MapKit
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import SwiftUI

// MARK: - PortraitNavigationOverlayView

struct PortraitNavigationOverlayView<T: SpokenInstructionObserver & ObservableObject>: View,
CustomizableNavigatingInnerGridView, NavigationOverlayContent {

    // MARK: Properties

    @Environment(\.navigationFormatterCollection) var formatterCollection: any FormatterCollection

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
        self.showMute = showMute
        self.showZoom = showZoom
        self.onMute = onMute
        self.onZoomIn = onZoomIn
        self.onZoomOut = onZoomOut
        self.showCentering = showCentering
        self.onCenter = onCenter
    }

    // MARK: Content

    var body: some View {
        ZStack(alignment: .top) {
            VStack {
                Spacer()

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

                if let progressView = overlayStore.content[.tripProgress] {
                    progressView()
                }
            }

            if let instructionsView = overlayStore.content[.instructions] {
                instructionsView()
            }
        }
    }
}

// MARK: - LegacyInstructionsView

struct LegacyInstructionsView: View {

    // MARK: Properties

    @Environment(\.navigationFormatterCollection) var formatterCollection: any FormatterCollection
    let navigationState: NavigationState

    @State private var isInstructionViewExpanded: Bool = false
    @State private var instructionsViewSizeWhenNotExpanded: CGSize = .zero

    // MARK: Lifecycle

    init(navigationState: NavigationState) {
        self.navigationState = navigationState
    }

    // MARK: Content

    var body: some View {
        VStack {
            if let visualInstruction = navigationState.currentVisualInstruction,
               let progress = navigationState.currentProgress,
               navigationState.isNavigating {
                let remainingSteps = self.navigationState.remainingSteps

                InstructionsView(
                    visualInstruction: visualInstruction,
                    distanceFormatter: self.formatterCollection.distanceFormatter,
                    distanceToNextManeuver: progress.distanceToNextManeuver,
                    remainingSteps: remainingSteps,
                    isExpanded: self.$isInstructionViewExpanded,
                    sizeWhenNotExpanded: self.$instructionsViewSizeWhenNotExpanded
                )
            }
        }.padding(.top, self.instructionsViewSizeWhenNotExpanded.height + 16)
    }
}
