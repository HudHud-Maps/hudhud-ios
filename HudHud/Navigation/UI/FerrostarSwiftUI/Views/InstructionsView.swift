//
//  InstructionsView.swift
//  HudHud
//
//  Created by Ali Hilal on 03.11.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import FerrostarCore
import FerrostarCoreFFI
import MapKit
import SwiftUI

/// The core instruction view. This displays the current step with it's primary and secondary instruction.
public struct InstructionsView: View {

    // MARK: Properties

    private let visualInstruction: VisualInstruction
    private let distanceToNextManeuver: CLLocationDistance?
    private let distanceFormatter: Formatter
    private let remainingSteps: [RouteStep]?

    private let primaryRowTheme: InstructionRowTheme
    private let secondaryRowTheme: InstructionRowTheme
    private let verticalPadding: CGFloat = 16

    @Binding private var isExpanded: Bool

    @Binding private var sizeWhenNotExpanded: CGSize

    @Environment(\.safeAreaInsets) private var safeAreaInsets

    // MARK: Computed Properties

    public var expandedContent: AnyView? {
        guard !self.nextVisualInstructions.isEmpty else {
            return nil
        }
        return AnyView(ForEach(Array(self.nextVisualInstructions.enumerated()), id: \.0) { enumerated in
            let (visualInstruction, step): (VisualInstruction, RouteStep) = enumerated.1
            Divider().padding(.leading, 16)
            DefaultIconographyManeuverInstructionView(text: visualInstruction.primaryContent.text,
                                                      maneuverType: visualInstruction.primaryContent.maneuverType,
                                                      maneuverModifier: visualInstruction.primaryContent.maneuverModifier,
                                                      distanceFormatter: self.distanceFormatter,
                                                      distanceToNextManeuver: step.distance == 0 ? nil : step.distance,
                                                      theme: self.primaryRowTheme)
                .font(.title2.bold())
                .padding(.horizontal, 16)
        })
    }

    private var hasSecondary: Bool {
        self.visualInstruction.secondaryContent != nil
    }

    /// The visual instructions *after* the one for the current maneuver,
    /// paired with the route step.
    ///
    /// Note that in the case of steps with multiple instructions,
    /// only the first is returned in this list.
    /// This is sufficient for display of the upcoming maneuver list.
    private var nextVisualInstructions: [(VisualInstruction, RouteStep)] {
        guard let remainingSteps, remainingSteps.count > 1 else {
            return []
        }
        return remainingSteps[1...].compactMap { step in
            guard let visualInstruction = step.visualInstructions.first else {
                return nil
            }
            return (visualInstruction, step)
        }
    }

    // MARK: Lifecycle

    /// Create a visual instruction banner view. This view automatically displays the secondary
    /// instruction if there is one.
    ///
    /// - Parameters:
    ///   - visualInstruction: The visual instruction to display.
    ///   - distanceFormatter: The formatter which controls distance localization.
    ///   - distanceToNextManeuver: The distance remaining for the step.
    ///   - remainingSteps: All steps remaining in the route, including the current step.
    ///   - primaryRowTheme: The theme for the primary instruction.
    ///   - secondaryRowTheme: The theme for the secondary instruction.
    ///   - isExpanded: Whether the instruction view is currently expanded.
    ///   - sizeWhenNotExpanded: The size of the InstructionsView when minimized. You may use this for allocating space
    /// for the instruction view in your layout. This property is automatically updated by the instruction view as its
    /// size changes.
    public init(visualInstruction: VisualInstruction,
                distanceFormatter: Formatter = DefaultFormatters.distanceFormatter,
                distanceToNextManeuver: CLLocationDistance? = nil,
                remainingSteps: [RouteStep]? = nil,
                primaryRowTheme: InstructionRowTheme = DefaultInstructionRowTheme(),
                secondaryRowTheme: InstructionRowTheme = DefaultSecondaryInstructionRowTheme(),
                isExpanded: Binding<Bool> = .constant(false),
                sizeWhenNotExpanded: Binding<CGSize> = .constant(.zero)) {
        self.visualInstruction = visualInstruction
        self.distanceFormatter = distanceFormatter
        self.distanceToNextManeuver = distanceToNextManeuver
        self.remainingSteps = remainingSteps
        self.primaryRowTheme = primaryRowTheme
        self.secondaryRowTheme = secondaryRowTheme
        _isExpanded = isExpanded
        _sizeWhenNotExpanded = sizeWhenNotExpanded
    }

    // MARK: Content

    public var body: some View {
        TopDrawerView(backgroundColor: self.primaryRowTheme.backgroundColor,
                      isExpanded: self.$isExpanded,
                      persistentContent: {
                          VStack(spacing: 0) {
                              DefaultIconographyManeuverInstructionView(text: self.visualInstruction.primaryContent.text,
                                                                        maneuverType: self.visualInstruction.primaryContent.maneuverType,
                                                                        maneuverModifier: self.visualInstruction.primaryContent.maneuverModifier,
                                                                        distanceFormatter: self.distanceFormatter,
                                                                        distanceToNextManeuver: self.distanceToNextManeuver == 0 ? nil : self
                                                                            .distanceToNextManeuver,
                                                                        theme: self.primaryRowTheme)
                                  .font(.title2.bold())
                                  .padding(.horizontal, 16)
                                  .padding(.top, self.safeAreaInsets.top + self.verticalPadding)
                                  .padding(.bottom, self.hasSecondary ? 8 : self.verticalPadding)

                              if let secondaryContent = visualInstruction.secondaryContent {
                                  DefaultIconographyManeuverInstructionView(text: secondaryContent.text,
                                                                            maneuverType: secondaryContent.maneuverType,
                                                                            maneuverModifier: secondaryContent.maneuverModifier,
                                                                            distanceFormatter: self.distanceFormatter,
                                                                            theme: self.secondaryRowTheme)
                                      .padding(.horizontal, 16)
                                      .padding(.top, 8)
                                      .padding(.bottom, self.verticalPadding)
                                      .background(self.secondaryRowTheme.backgroundColor)
                              }
                          }.overlay(GeometryReader { geometry in
                              Color.clear.onAppear {
                                  self.sizeWhenNotExpanded = geometry.size
                              }.onChange(of: geometry.size) { _, newValue in
                                  self.sizeWhenNotExpanded = newValue
                              }.onDisappear {
                                  self.sizeWhenNotExpanded = .zero
                              }
                          })
                      },
                      expandedContent: { self.expandedContent })
    }
}

#Preview {
    let germanFormatter = MKDistanceFormatter()
    germanFormatter.locale = Locale(identifier: "de_DE")
    germanFormatter.units = .metric

    return VStack(spacing: 16) {
        InstructionsView(visualInstruction: VisualInstruction(primaryContent: VisualInstructionContent(text: "Turn right on Something Dr.",
                                                                                                       maneuverType: .turn,
                                                                                                       maneuverModifier: .right,
                                                                                                       roundaboutExitDegrees: nil,
                                                                                                       laneInfo: nil),
                                                              secondaryContent: VisualInstructionContent(text: "Merge onto Hwy 123",
                                                                                                         maneuverType: .merge,
                                                                                                         maneuverModifier: .right,
                                                                                                         roundaboutExitDegrees: nil,
                                                                                                         laneInfo: nil),
                                                              subContent: nil,
                                                              triggerDistanceBeforeManeuver: 123))

        InstructionsView(visualInstruction: VisualInstruction(primaryContent: VisualInstructionContent(text: "Use the second exit to leave the roundabout.",
                                                                                                       maneuverType: .rotary,
                                                                                                       maneuverModifier: .slightRight,
                                                                                                       roundaboutExitDegrees: nil,
                                                                                                       laneInfo: nil),
                                                              secondaryContent: nil,
                                                              subContent: nil,
                                                              triggerDistanceBeforeManeuver: 123))

        InstructionsView(visualInstruction: VisualInstruction(primaryContent: VisualInstructionContent(text: "Links einfädeln.",
                                                                                                       maneuverType: .merge,
                                                                                                       maneuverModifier: .slightLeft,
                                                                                                       roundaboutExitDegrees: nil,
                                                                                                       laneInfo: nil),
                                                              secondaryContent: nil,
                                                              subContent: nil,
                                                              triggerDistanceBeforeManeuver: 123),
                         distanceFormatter: germanFormatter,
                         distanceToNextManeuver: 1500.0)

        InstructionsView(visualInstruction: VisualInstruction(primaryContent: VisualInstructionContent(text: "Turn right on Something Dr.",
                                                                                                       maneuverType: .turn,
                                                                                                       maneuverModifier: .right,
                                                                                                       roundaboutExitDegrees: nil,
                                                                                                       laneInfo: nil),
                                                              secondaryContent: VisualInstructionContent(text: "Merge onto Hwy 123",
                                                                                                         maneuverType: .merge,
                                                                                                         maneuverModifier: .right,
                                                                                                         roundaboutExitDegrees: nil,
                                                                                                         laneInfo: nil),
                                                              subContent: nil,
                                                              triggerDistanceBeforeManeuver: 123))

        Spacer()
    }
    .padding()
    .background(Color.green)
}

#Preview("Many steps") {
    VStack(spacing: 16) {
        InstructionsView(visualInstruction: VisualInstructionFactory().build(),
                         distanceToNextManeuver: 1500,
                         remainingSteps: RouteStepFactory().buildMany(10))

        Spacer()
    }
    .padding()
    .background(Color.green)
}

#Preview("Many steps, expanded") {
    VStack(spacing: 16) {
        InstructionsView(visualInstruction: VisualInstructionFactory().build(),
                         distanceToNextManeuver: 1500,
                         remainingSteps: RouteStepFactory().buildMany(10),
                         isExpanded: .constant(true))

        Spacer()
    }
    .padding()
    .background(Color.green)
}

#Preview("Many steps with secondary") {
    VStack(spacing: 16) {
        InstructionsView(visualInstruction: VisualInstructionFactory().secondaryContent { n in
            VisualInstructionContentFactory().text { n in
                RoadNameFactory().baseName { _ in "Street" }.build(n)
            }.build(n)
        }.build(),
        distanceToNextManeuver: 1500,
        remainingSteps: RouteStepFactory().buildMany(10))

        Spacer()
    }
    .padding()
    .background(Color.green)
}
