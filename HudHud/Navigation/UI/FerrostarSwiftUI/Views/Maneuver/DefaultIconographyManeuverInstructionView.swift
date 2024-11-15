//
//  DefaultIconographyManeuverInstructionView.swift
//  HudHud
//
//  Created by Ali Hilal on 03.11.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import FerrostarCoreFFI
import MapKit
import SwiftUI

/// A maneuver instruction view with reasonable default iconography.
///
/// This view will display the maneuver icon using the public domain
/// icons from Mapbox.
public struct DefaultIconographyManeuverInstructionView: View {

    // MARK: Properties

    private let text: String
    private let maneuverType: ManeuverType?
    private let maneuverModifier: ManeuverModifier?
    private let distanceToNextManeuver: CLLocationDistance?
    private let distanceFormatter: Formatter
    private let theme: InstructionRowTheme

    // MARK: Lifecycle

    /// Initialize a maneuver instruction view that includes a leading icon.
    /// As an HStack, this view automatically corrects for .rightToLeft languages.
    ///
    /// - Parameters:
    ///   - text: The maneuver instruction.
    ///   - maneuverType: The maneuver type defines the behavior.
    ///   - maneuverModifier: The maneuver modifier defines the direction.
    ///   - distanceFormatter: The formatter which controls distance localization.
    ///   - distanceToNextManeuver: A string that should represent the localized distance remaining.
    ///   - theme: The instruction row theme specifies attributes like colors and fonts for the row.
    public init(
        text: String,
        maneuverType: ManeuverType?,
        maneuverModifier: ManeuverModifier?,
        distanceFormatter: Formatter,
        distanceToNextManeuver: CLLocationDistance? = nil,
        theme: InstructionRowTheme = DefaultInstructionRowTheme()
    ) {
        self.text = text
        self.maneuverType = maneuverType
        self.maneuverModifier = maneuverModifier
        self.distanceFormatter = distanceFormatter
        self.distanceToNextManeuver = distanceToNextManeuver
        self.theme = theme
    }

    // MARK: Content

    public var body: some View {
        ManeuverInstructionView(
            text: self.text,
            distanceFormatter: self.distanceFormatter,
            distanceToNextManeuver: self.distanceToNextManeuver,
            theme: self.theme
        ) {
            if let maneuverType {
                ManeuverImage(
                    maneuverType: maneuverType,
                    maneuverModifier: self.maneuverModifier
                )
                .frame(maxWidth: 48)
                // REVIEW: without this, the first image in the vstack was rendering very small. Curiously subsequent items in the vstack looked reasonable.
                .aspectRatio(contentMode: .fill)
            }
        }
    }
}

#Preview("Default formatter") {
    DefaultIconographyManeuverInstructionView(
        text: "Merge Left onto Something",
        maneuverType: .merge,
        maneuverModifier: .left,
        distanceFormatter: MKDistanceFormatter(),
        distanceToNextManeuver: 1500.0
    )
}

#Preview("Custom formatter (US Imperial)") {
    let formatter = MKDistanceFormatter()
    formatter.locale = Locale(identifier: "en-US")
    formatter.units = .imperial

    return DefaultIconographyManeuverInstructionView(
        text: "Merge Left onto Something",
        maneuverType: .merge,
        maneuverModifier: .left,
        distanceFormatter: formatter,
        distanceToNextManeuver: 1500.0
    )
}

#Preview("Custom formatter (DE)") {
    let formatter = MKDistanceFormatter()
    formatter.locale = Locale(identifier: "de-DE")
    formatter.units = .metric

    return DefaultIconographyManeuverInstructionView(
        text: "Merge Left onto Something",
        maneuverType: .merge,
        maneuverModifier: .left,
        distanceFormatter: formatter,
        distanceToNextManeuver: 1500.0
    )
}

#Preview("Custom formatter (UK)") {
    let formatter = MKDistanceFormatter()
    formatter.locale = Locale(identifier: "en-GB")
    formatter.units = .imperialWithYards

    return DefaultIconographyManeuverInstructionView(
        text: "Merge Left onto Something",
        maneuverType: .merge,
        maneuverModifier: .left,
        distanceFormatter: formatter,
        distanceToNextManeuver: 300.0
    )
}
