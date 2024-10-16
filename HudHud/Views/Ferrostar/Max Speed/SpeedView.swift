//
//  SpeedView.swift
//  HudHud
//
//  Created by Naif Alrashed on 13/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import SwiftUI

// MARK: - SpeedView

struct SpeedView: View {

    // MARK: Properties

    let speed: Measurement<UnitSpeed>?
    let speedLimit: Measurement<UnitSpeed>?

    // MARK: Computed Properties

    private var isOverSpeedLimit: Bool {
        if let speedLimit, let speed, speed > speedLimit {
            true
        } else {
            false
        }
    }

    // MARK: Lifecycle

    init(speed: Measurement<UnitSpeed>?, speedLimit: Measurement<UnitSpeed>?) {
        self.speed = speed?
            .converted(to: speedLimit?.unit ?? .kilometersPerHour)
        self.speedLimit = speedLimit
    }

    // MARK: Content

    var body: some View {
        CurrentSpeedView(
            speed: self.speed,
            isOverSpeedLimit: self.isOverSpeedLimit
        )
        .overlay(alignment: .topTrailing) {
            if let speedLimit {
                Circle().fill(.red).frame(width: 10)
                    .overlay {
                        SpeedLimitView(speedLimit: speedLimit)
                    }
            }
        }
    }
}

// MARK: - CurrentSpeedView

struct CurrentSpeedView: View {

    // MARK: Properties

    let speed: Measurement<UnitSpeed>?
    let isOverSpeedLimit: Bool

    // MARK: Computed Properties

    private var speedColor: Color {
        if self.isOverSpeedLimit {
            .red
        } else {
            .white
        }
    }

    private var speedValue: LocalizedStringKey {
        if let speed {
            "\(speed, formatter: speedFormatter.numberFormatter)"
        } else {
            "_"
        }
    }

    private var speedUnit: LocalizedStringKey {
        if let speed {
            "\(speed.unit, formatter: speedFormatter)"
        } else {
            "km/h"
        }
    }

    // MARK: Content

    var body: some View {
        VStack(spacing: 2) {
            Text(self.speedValue)
                .foregroundStyle(self.speedColor)
                .hudhudFont(.headline)
            Text(self.speedUnit)
                .foregroundStyle(.white)
        }
        .padding(12)
        .background(Circle().fill(Color.Colors.General._01Black))
    }
}

// MARK: - SpeedLimitView

struct SpeedLimitView: View {

    // MARK: Properties

    let speedLimit: Measurement<UnitSpeed>

    // MARK: Lifecycle

    init(speedLimit: Measurement<UnitSpeed>) {
        self.speedLimit = speedLimit
    }

    // MARK: Content

    var body: some View {
        Text("\(self.speedLimit, formatter: speedFormatter.numberFormatter)")
            .lineLimit(1, reservesSpace: true)
            .foregroundStyle(Color.Colors.General._17Text)
            .padding(12)
            .background(Circle().fill(.white))
            .padding(3.5)
            .background(Circle().fill(.red))
            .frame(minWidth: 100, minHeight: 100)
    }
}

// MARK: - OverSpeedLimitNotificationView

struct OverSpeedLimitNotificationView: View {

    // MARK: Properties

    let currentSpeed: CLLocationSpeed

    // MARK: Content

    var body: some View {
        Text("\(NSNumber(floatLiteral: self.currentSpeed), formatter: speedFormatter.numberFormatter)")
            .foregroundStyle(.white)
            .padding(12)
            .background(Circle().fill(.red))
            .padding(3.5)
            .background(Circle().fill(.white))
            .padding(3.5)
            .background(Circle().fill(.red))
    }
}

#Preview {
    SpeedView(
        speed: Measurement<UnitSpeed>(value: 50, unit: .kilometersPerHour),
        speedLimit: Measurement<UnitSpeed>(value: 60, unit: .kilometersPerHour)
    )
    SpeedView(
        speed: Measurement<UnitSpeed>(value: 60, unit: .kilometersPerHour),
        speedLimit: Measurement<UnitSpeed>(value: 50, unit: .kilometersPerHour)
    )
    SpeedLimitView(
        speedLimit: Measurement<UnitSpeed>(value: 120, unit: .kilometersPerHour)
    )
}

private let speedFormatter: MeasurementFormatter = {
    let formatter = MeasurementFormatter()
    formatter.unitOptions = .providedUnit
    formatter.unitStyle = .short
    return formatter
}()

#Preview("over speed limit notification") {
    OverSpeedLimitNotificationView(currentSpeed: 121)
        .environment(\.locale, Locale(identifier: "ar_sa"))
    OverSpeedLimitNotificationView(currentSpeed: 500)
}
