//
//  DirectionsSummaryView.swift
//  HudHud
//
//  Created by Alaa . on 19/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

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
		formatter.allowedUnits = [.hour, .minute, .second]
		formatter.unitsStyle = .short
		if let formattedString = formatter.string(from: duration) {
			return formattedString
		} else {
			return "-"
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
	DirectionsSummaryView(
		directionPreviewData: DirectionPreviewData(
			duration: 1200,
			distance: Measurement(
				value: 4.4,
				unit: UnitLength.kilometers
			),
			typeOfRoute: "Fastest"
		), go: {}
	)
	.padding()
}
