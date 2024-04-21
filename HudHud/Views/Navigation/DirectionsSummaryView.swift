//
//  DirectionsSummaryView.swift
//  HudHud
//
//  Created by Alaa . on 19/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import MapboxCoreNavigation
import MapboxDirections
import SwiftUI

struct DirectionsSummaryView: View {
	var directionPreviewData: DirectionPreviewData
	var go: () -> Void

	var body: some View {
		HStack {
			VStack(alignment: .leading) {
				// 20 min AKA duration
				Text(self.formatDuration(duration: self.directionPreviewData.duration))
					.font(.system(.largeTitle))
					.fontWeight(.semibold)
					.lineLimit(1)
					.minimumScaleFactor(0.5)
				// distance • type of route
				Text("\(self.formatDistance(distance: self.directionPreviewData.distance)) • \(self.directionPreviewData.typeOfRoute)")
					.font(.system(.body))
					.lineLimit(1)
					.minimumScaleFactor(0.5)
			}
			Spacer()
			// Go button
			Button {
				self.go()
			} label: {
				Text("Go")
					.font(.system(.title2))
					.bold()
					.lineLimit(1)
					.minimumScaleFactor(0.5)
					.foregroundStyle(Color.white)
					.padding()
					.padding(.horizontal)
					.background(.blue)
					.cornerRadius(8)
			}
		}
		.frame(maxWidth: .infinity)
		.cornerRadius(8)
	}

	// MARK: - Internal

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

#Preview {
	DirectionsSummaryView(
		directionPreviewData: DirectionPreviewData(
			duration: 1200,
			distance: 4.4,
			typeOfRoute: "Fastest"
		), go: {}
	)
	.padding()
}
