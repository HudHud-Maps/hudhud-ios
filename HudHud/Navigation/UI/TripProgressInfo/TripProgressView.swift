//
//  TripProgressView.swift
//  HudHud
//
//  Created by Ali Hilal on 09/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct TripProgressView: View {

    // MARK: Properties

    let distanceFormatter: Formatter
    let estimatedArrivalFormatter: Date.FormatStyle
    let durationFormatter: DateComponentsFormatter
    let isExpanded: Bool
    let fromDate: Date = .init()

    private let tripProgress: TripProgress
    private let onAction: (ActiveTripInfoViewAction) -> Void

    // MARK: Lifecycle

    init(tripProgress: TripProgress, isExpanded: Bool, onAction: @escaping (ActiveTripInfoViewAction) -> Void) {
        self.tripProgress = tripProgress
        self.onAction = onAction
        self.isExpanded = isExpanded
        self.distanceFormatter = DefaultFormatters.distanceFormatter
        self.estimatedArrivalFormatter = DefaultFormatters.estimatedArrivalFormat
        self.durationFormatter = DefaultFormatters.durationFormat
    }

    // MARK: Content

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    if let formattedDuration = durationFormatter.string(from: tripProgress.durationRemaining) {
                        Text(formattedDuration)
                            .hudhudFont(.title2)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .multilineTextAlignment(.center)
                    }

                    HStack(alignment: .center, spacing: 4) {
                        Text(self.estimatedArrivalFormatter.format(self.tripProgress.estimatedArrival(from: self.fromDate)))
                            .hudhudFont(.callout)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .foregroundStyle(Color.Colors.General._02Grey)
                            .multilineTextAlignment(.center)

                        Text("·")
                            .hudhudFont(.callout)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .foregroundStyle(Color.Colors.General._02Grey)
                            .multilineTextAlignment(.center)

                        Text(self.distanceFormatter.string(for: self.tripProgress.distanceRemaining) ?? "")
                            .hudhudFont(.callout)
                            .fontWeight(.semibold)
                            //                                .minimumScaleFactor(0.6)
                            .lineLimit(1)
                            .foregroundStyle(Color.Colors.General._02Grey)
                            .multilineTextAlignment(.center)
                    }
                }

                Spacer()

                NavigationControls(isCompact: true, onAction: self.onAction)
            }
            if self.isExpanded {
                Divider()
                NavigationSettingsRow()
            }
        }
    }
}
