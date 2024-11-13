//
//  ArrivalView.swift
//  HudHud
//
//  Created by Ali Hilal on 03.11.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import FerrostarCore
import FerrostarCoreFFI
import MapKit
import SwiftUI

public struct ArrivalView: View {

    // MARK: Properties

    let progress: TripProgress
    let distanceFormatter: Formatter
    let estimatedArrivalFormatter: Date.FormatStyle
    let durationFormatter: DateComponentsFormatter
    let theme: any ArrivalViewTheme
    let fromDate: Date
    let onTapExit: (() -> Void)?

    // MARK: Lifecycle

    /// Initialize the ArrivalView
    ///
    /// - Parameters:
    ///   - progress: The current Trip Progress providing durations and distances.
    ///   - distanceFormatter: The distance formatter to use when displaying the remaining trip distance.
    ///   - estimatedArrivalFormatter: The estimated time of arrival Date-Time formatter.
    ///   - durationFormatter: The duration remaining formatter.
    ///   - theme: The arrival view theme.
    ///   - fromDate: The date time to estimate arrival from, primarily for testing (default is now).
    ///   - onTapExit: The action to run when the exit button is tapped.
    public init(progress: TripProgress,
                distanceFormatter: Formatter = DefaultFormatters.distanceFormatter,
                estimatedArrivalFormatter: Date.FormatStyle = DefaultFormatters.estimatedArrivalFormat,
                durationFormatter: DateComponentsFormatter = DefaultFormatters.durationFormat,
                theme: any ArrivalViewTheme = DefaultArrivalViewTheme(),
                fromDate: Date = Date(),
                onTapExit: (() -> Void)? = nil) {
        self.progress = progress
        self.distanceFormatter = distanceFormatter
        self.estimatedArrivalFormatter = estimatedArrivalFormatter
        self.durationFormatter = durationFormatter
        self.theme = theme
        self.fromDate = fromDate
        self.onTapExit = onTapExit
    }

    // MARK: Content

    public var body: some View {
        HStack {
            VStack {
                Text(self.estimatedArrivalFormatter.format(self.progress.estimatedArrival(from: self.fromDate)))
                    .font(self.theme.measurementFont)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .foregroundStyle(self.theme.measurementColor)
                    .multilineTextAlignment(.center)

                if self.theme.style == .informational {
                    Text("Arrival", bundle: .main)
                        .font(self.theme.secondaryFont)
                        .foregroundStyle(self.theme.secondaryColor)
                }
            }

            if let formattedDuration = durationFormatter.string(from: progress.durationRemaining) {
                VStack {
                    Text(formattedDuration)
                        .font(self.theme.measurementFont)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .foregroundStyle(self.theme.measurementColor)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)

                    if self.theme.style == .informational {
                        Text("Duration", bundle: .main)
                            .font(self.theme.secondaryFont)
                            .foregroundStyle(self.theme.secondaryColor)
                    }
                }
            }

            VStack {
                Text(self.distanceFormatter.string(for: self.progress.distanceRemaining) ?? "")
                    .font(self.theme.measurementFont)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .foregroundStyle(self.theme.measurementColor)
                    .multilineTextAlignment(.center)

                if self.theme.style == .informational {
                    Text("Distance", bundle: .main)
                        .font(self.theme.secondaryFont)
                        .foregroundStyle(self.theme.secondaryColor)
                }
            }

            if let onTapExit {
                Button {
                    onTapExit()
                } label: {
                    Image(systemSymbol: .xmark)
                        .foregroundColor(self.theme.measurementColor)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(Capsule())
            } else {
                Rectangle()
                    .frame(width: 20, height: 10)
                    .foregroundColor(.clear)
            }
        }
        .padding(.leading, 32)
        .padding(.trailing, 12)
        .padding(.vertical, 8)
        .background(self.theme.backgroundColor)
        .clipShape(.rect(cornerRadius: 48))
        .shadow(radius: 12)
    }
}

#Preview {
    var informationalTheme: any ArrivalViewTheme {
        var theme = DefaultArrivalViewTheme()
        theme.style = .informational
        return theme
    }

    return VStack(spacing: 16) {
        ArrivalView(progress: TripProgress(distanceToNextManeuver: 123,
                                           distanceRemaining: 120,
                                           durationRemaining: 150))

        ArrivalView(progress: TripProgress(distanceToNextManeuver: 123,
                                           distanceRemaining: 14500,
                                           durationRemaining: 1234))

        ArrivalView(progress: TripProgress(distanceToNextManeuver: 123,
                                           distanceRemaining: 14500,
                                           durationRemaining: 12234),
                    theme: informationalTheme)
            .environment(\.locale, Locale(identifier: "de_DE"))

        ArrivalView(progress: TripProgress(distanceToNextManeuver: 5420,
                                           distanceRemaining: 1_420_000,
                                           durationRemaining: 520_800),
                    theme: informationalTheme)

        Spacer()
    }
    .padding()
    .background(Color.green)
}

#Preview("ArrivalView With Action") {
    var informationalTheme: any ArrivalViewTheme {
        var theme = DefaultArrivalViewTheme()
        theme.style = .informational
        return theme
    }

    return VStack(spacing: 16) {
        ArrivalView(progress: TripProgress(distanceToNextManeuver: 123,
                                           distanceRemaining: 120,
                                           durationRemaining: 150),
                    onTapExit: {})

        ArrivalView(progress: TripProgress(distanceToNextManeuver: 123,
                                           distanceRemaining: 14500,
                                           durationRemaining: 1234),
                    onTapExit: {})

        ArrivalView(progress: TripProgress(distanceToNextManeuver: 123,
                                           distanceRemaining: 14500,
                                           durationRemaining: 12234),
                    theme: informationalTheme,
                    onTapExit: {})
            .environment(\.locale, Locale(identifier: "de_DE"))

        ArrivalView(progress: TripProgress(distanceToNextManeuver: 5420,
                                           distanceRemaining: 1_420_000,
                                           durationRemaining: 520_800),
                    theme: informationalTheme,
                    onTapExit: {})

        Spacer()
    }
    .padding()
    .background(Color.green)
}
