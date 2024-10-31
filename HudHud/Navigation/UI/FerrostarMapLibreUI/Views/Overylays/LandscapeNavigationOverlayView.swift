import FerrostarCore
import MapKit
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import SwiftUI

struct LandscapeNavigationOverlayView: View, CustomizableNavigatingInnerGridView {

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

    var onTapExit: (() -> Void)?

    let showMute: Bool
    let isMuted: Bool
    let onMute: () -> Void

    private let navigationState: NavigationState?

    @State private var isInstructionViewExpanded: Bool = false

    // MARK: Lifecycle

    init(
        navigationState: NavigationState?,
        speedLimit: Measurement<UnitSpeed>? = nil,
        isMuted: Bool,
        showMute: Bool = true,
        onMute: @escaping () -> Void,
        showZoom: Bool = false,
        onZoomIn: @escaping () -> Void = {},
        onZoomOut: @escaping () -> Void = {},
        showCentering: Bool = false,
        onCenter: @escaping () -> Void = {},
        onTapExit: (() -> Void)? = nil
    ) {
        self.navigationState = navigationState
        self.speedLimit = speedLimit
        self.isMuted = isMuted
        self.onMute = onMute
        self.showMute = showMute
        self.showZoom = showZoom
        self.onZoomIn = onZoomIn
        self.onZoomOut = onZoomOut
        self.showCentering = showCentering
        self.onCenter = onCenter
        self.onTapExit = onTapExit
    }

    // MARK: Content

    var body: some View {
        HStack {
            ZStack(alignment: .top) {
                VStack {
                    Spacer()
                    if case .navigating = self.navigationState?.tripState,
                       let progress = navigationState?.currentProgress {
                        ArrivalView(
                            progress: progress,
                            onTapExit: self.onTapExit
                        )
                    }
                }
                if case .navigating = self.navigationState?.tripState,
                   let visualInstruction = navigationState?.currentVisualInstruction,
                   let progress = navigationState?.currentProgress,
                   let remainingSteps = navigationState?.remainingSteps {
                    InstructionsView(
                        visualInstruction: visualInstruction,
                        distanceFormatter: self.formatterCollection.distanceFormatter,
                        distanceToNextManeuver: progress.distanceToNextManeuver,
                        remainingSteps: remainingSteps,
                        isExpanded: self.$isInstructionViewExpanded
                    )
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
