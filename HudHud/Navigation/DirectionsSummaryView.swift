//
//  DirectionPreview.swift
//  HudHud
//
//  Created by Alaa . on 19/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct DirectionsSummaryView: View {
	var directionPreviewData: DirectionPreviewData
    var body: some View {
			HStack {
				VStack(alignment: .leading) {
					// 20 min AKA duration
					Text(formatDuration(duration: directionPreviewData.duration))
						.font(.system(.title2))
						.bold()
						.lineLimit(1)
						.minimumScaleFactor(0.5)
						// distance • type of route
					Text("\(formatDistance(distance: directionPreviewData.distance)) • \(directionPreviewData.typeOfRoute)")
							.font(.system(.body))
							.lineLimit(1)
							.minimumScaleFactor(0.5)
				}
				Spacer()
				// Go button
				Button {
					print("Starting Direction")
				} label: {
					Text("Go")
						.font(.system(.body))
						.bold()
						.lineLimit(1)
						.minimumScaleFactor(0.5)
						.foregroundStyle(Color.white)
						.padding()
						.padding(.horizontal)
						.background(.green)
						.cornerRadius(8)
				}
			}
			.padding()
			.frame(maxWidth: .infinity)
			.background(.tertiary)
			.cornerRadius(8)
    }

	func formatDuration(duration: TimeInterval) -> String {
		let formatter = DateComponentsFormatter()
			   formatter.allowedUnits = [.hour, .minute, .second]
			   formatter.unitsStyle = .brief
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
			duration: 1_200,
			distance: Measurement(
				value: 4.4,
				unit: UnitLength.kilometers
			),
			typeOfRoute: "Fastest"
		)
	)
	.padding()
}
