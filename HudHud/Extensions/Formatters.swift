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
		let formatter = MeasurementFormatter()
		let locale = Locale.autoupdatingCurrent
		formatter.locale = locale
		formatter.unitOptions = .providedUnit
		formatter.unitStyle = .short

		let distanceMeasurement = Measurement(value: distance, unit: UnitLength.meters)

		// Check if distance is less than 1000 meters
		if distance < 1000 {
			// Round up to the next 50 meters increment
			let roundedDistance = (distance / 50.0).rounded(.up) * 50.0
			return "\(Int(roundedDistance))m"
		} else {
			// Format distance in kilometers with one decimal place
			let distanceInKilometers = distanceMeasurement.converted(to: .kilometers)
			formatter.numberFormatter.maximumFractionDigits = 1
			return formatter.string(from: distanceInKilometers)
		}
	}
}
