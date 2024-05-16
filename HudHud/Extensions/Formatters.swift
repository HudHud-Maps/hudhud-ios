//
//  Formatters.swift
//  HudHud
//
//  Created by Alaa . on 02/05/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//
import CoreLocation
import Foundation
import MapboxCoreNavigation
import MapboxDirections
import MapKit
import SwiftUI

class Formatters {
    func formatDuration(duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .short
        if let formattedString = formatter.string(from: duration) {
            return formattedString
        } else {
            return "-"
        }
    }

    func formatDistance(distance: CLLocationDistance) -> String {
        let locale = Locale.autoupdatingCurrent

        let distanceMeasurement = Measurement(value: distance, unit: UnitLength.meters)

        let stringDistance = distanceMeasurement.formatted(.measurement(width: .abbreviated, usage: .road).locale(locale))

        return stringDistance
    }

}
