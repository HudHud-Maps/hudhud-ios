//
//  AlertView.swift
//  HudHud
//
//  Created by Ali Hilal on 06/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

// MARK: - AlertInfo

import CoreLocation

// MARK: - NavigationAlert

struct NavigationAlert: Equatable {
    let id: String
    let progress: CGFloat
    let alertType: AlertType
    let alertDistance: Int
}

// MARK: - AlertType

enum AlertType: Equatable {
    case speedCamera(SpeedCamera)
    case carAccident(TrafficIncident)

    // MARK: Computed Properties

    var icon: String {
        switch self {
        case .speedCamera: return "camera.fill"
        case .carAccident: return "car.fill"
        }
    }

    var color: Color {
        switch self {
        case .speedCamera: return .red
        case .carAccident: return .red
        }
    }

    var title: String {
        switch self {
        case .speedCamera: return "Speed Camera"
        case .carAccident: return "Car Accident"
        }
    }
}

// MARK: - AlertView

struct AlertView: View {

    // MARK: Properties

    let info: NavigationAlert
    let distanceFormatter: Formatter
    let estimatedArrivalFormatter: Date.FormatStyle
    let durationFormatter: DateComponentsFormatter
    let isExpanded: Bool
    let fromDate: Date = .init()

    private let tripProgress: TripProgress
    private let onAction: (ActiveTripInfoViewAction) -> Void

    // MARK: Lifecycle

    init(
        tripProgress: TripProgress,
        info: NavigationAlert,
        isExpanded: Bool,
        onAction: @escaping (ActiveTripInfoViewAction) -> Void
    ) {
        self.tripProgress = tripProgress
        self.info = info
        self.onAction = onAction
        self.isExpanded = isExpanded
        self.distanceFormatter = DefaultFormatters.distanceFormatter
        self.estimatedArrivalFormatter = DefaultFormatters.estimatedArrivalFormat
        self.durationFormatter = DefaultFormatters.durationFormat
    }

    // MARK: Content

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                if let formattedDuration = durationFormatter.string(from: tripProgress.durationRemaining) {
                    Text(formattedDuration)
                }

                Text("·")

                Text(self.estimatedArrivalFormatter.format(self.tripProgress.estimatedArrival(from: self.fromDate)))

                Text("·")

                Text(self.distanceFormatter.string(for: self.tripProgress.distanceRemaining) ?? "")
            }
            .hudhudFont(.body)
            .fontWeight(.semibold)
            .lineLimit(1)
            .foregroundStyle(Color.Colors.General._02Grey)
            .multilineTextAlignment(.center)
            .padding(.top, 16)

            GeometryReader { geometry in
                Rectangle()
                    .fill(self.info.alertType.color)
                    .frame(width: geometry.size.width * (self.info.progress / 100))
                    .frame(height: 2)
            }
            .frame(height: 2)
            .padding(.top, 16)

            Divider()

            HStack(spacing: 12) {
                Image(systemName: self.info.alertType.icon)
                    .foregroundColor(.white)
                    .font(.system(size: 20))
                    .frame(width: 40, height: 40)
                    .background(self.info.alertType.color)
                    .cornerRadius(8)

                Text("\(self.info.alertType.title) in \(self.info.alertDistance) m")
                    .hudhudFont(.title3)
                    .fontWeight(.semibold)
                    .padding(8)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            if self.isExpanded {
                VStack {
                    Divider()

                    NavigationControls(onAction: self.onAction)

                    Divider()

                    NavigationSettingsRow()
                }
                .padding(.top, 8)
            }
        }
        .background(Color.white)
        .cornerRadius(24)
    }
}
