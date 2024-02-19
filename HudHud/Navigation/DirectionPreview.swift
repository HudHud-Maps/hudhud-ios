//
//  DirectionPreview.swift
//  HudHud
//
//  Created by Alaa . on 19/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct DirectionPreview: View {
	var dir: DirectionPreviewData
    var body: some View {
		VStack {
			HStack {
				VStack(alignment: .leading) {
					// 20 min AKA duration
					Text(formatDuration(duration: dir.duration))
						.bold()
					HStack(spacing: 8.0) {
						// distance
						Text(formatDistance(distance: dir.distance))
						// type of route
						Text(dir.typeOfRoute)
					}
				}
				Spacer()
				// Go button
				Button {
					print("Starting Direction")
				} label: {
					Text("Go")
						.foregroundStyle(Color.white)
						.frame(width: 100, height: 60)
						.background(Color.green)
						.cornerRadius(8)
				}
			}
			.padding()
			.frame(maxWidth: .infinity, maxHeight: 84)
			.background(Color.gray)
			.cornerRadius(8)
		}
		.padding()
    }
	func formatDuration(duration: TimeInterval) -> String {
			let hours = Int(duration / 3600)
			let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
			if hours > 0 {
				if minutes > 0 {
					return "\(hours) hr \(minutes) min"
				} else {
					return "\(hours) hr"
				}
			} else {
				return "\(minutes) min"
			}
		}
	func formatDistance(distance: Measurement<UnitLength>) -> String {
			let formatter = MeasurementFormatter()
			formatter.unitOptions = .providedUnit
			formatter.unitStyle = .short
			return formatter.string(from: distance)
		}
}

#Preview {
	DirectionPreview(dir: DirectionPreviewData(duration: 1_250, distance: Measurement(value: 4.4, unit: UnitLength.kilometers), typeOfRoute: "Fastest"))
}
struct DirectionPreviewData {
	var duration: TimeInterval
	var distance: Measurement<UnitLength>
	var typeOfRoute: String
}
