//
//  TrafficChartData.swift
//  HudHud
//
//  Created by Fatima Aljaber on 27/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - TrafficChartData

struct TrafficChartData {

	let date: Date
	let traffic: [Double] // 24 items, 0:00 - 1:00 at index 0

	var getSpecificTrafficRange: [HourTrafficData]? {
		guard self.traffic.count == 24 else {
			print("Warning: got traffic with unexpected number of elements: \(self.traffic.count)...")
			return nil
		}
		var tempData: [HourTrafficData] = []
		for i in 9 ... 23 {
			if let dateRange = dateRangeForHour(hour: i) {
				let hour = HourTrafficData(hour: dateRange, traffic: traffic[i])
				tempData.append(hour)
			}
		}
		return tempData
	}

	// MARK: - Internal

	func dateRangeForHour(hour: Int) -> Range<Date>? {
		let calendar = Calendar.current
		let currentDate = Date()

		// Extract year, month, and day components
		let year = calendar.component(.year, from: currentDate)
		let month = calendar.component(.month, from: currentDate)
		let day = calendar.component(.day, from: currentDate)

		// Components for the start of the hour
		var startComponents = DateComponents()
		startComponents.year = year
		startComponents.month = month
		startComponents.day = day
		startComponents.hour = hour

		// Create the start date from components
		guard let startDate = calendar.date(from: startComponents) else {
			return nil
		}

		// Attempt to create the end date by adding nearly one hour to the start date
		guard let endDate = calendar.date(byAdding: .hour, value: 1, to: startDate)?.addingTimeInterval(-1) else {
			return nil
		}

		return startDate ..< endDate
	}
}

// MARK: - HourTrafficData

struct HourTrafficData: Identifiable {
	let hour: Range<Date>
	let traffic: Double

	var id: Range<Date> {
		return self.hour
	}
}
