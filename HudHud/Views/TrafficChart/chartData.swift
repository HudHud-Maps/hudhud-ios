//
//  chartData.swift
//  HudHud
//
//  Created by Fatima Aljaber on 27/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//
import Foundation
import SwiftUI
struct chartData:Identifiable{
	let id = UUID()
	let usualOccupancy: Double
	let usualOccupancyTime: TimeInterval
	var timeStart: Int
	var timeEnd: Int
	var hours: [hoursRange] {
		var hoursR: [hoursRange] = []
		for i in 0..<24 {
			let formatter = DateFormatter()
			formatter.dateFormat = "HH"
			formatter.locale =  Locale(identifier: "ar_AE")
			formatter.timeZone = TimeZone(abbreviation: "GMT")
			if let someDateTime = formatter.date(from: "\(i)") {
				hoursR.append(hoursRange(hour: someDateTime, trafficRange: 0.0))
			}
		}
		return hoursR
	}
	var getSpecificTraficRange: [hoursRange] {
		var range : [hoursRange] = hours
		let currentHour = Calendar.current.dateComponents([.hour], from: .now)
		let currentHourFormatted = "\(currentHour.hour ?? 0)".formattedHour
		for i in timeStart..<timeEnd {
			let formattedTime = "\(i)".formattedHour
				if let index = range.firstIndex(where: {$0.hour == formattedTime}) {
					// currently random traffic perecent
					range[index].trafficRange = Double.random(in: 0.0..<1.0)
					// checking the array of the traffic range to highlight the current hour
					range[index].currentHour = range[index].hour == currentHourFormatted ? true : false
				}
		}
		return range
	}
}
struct hoursRange:Identifiable{
	let id = UUID()
	var hour: Date
	var trafficRange: Double
	var currentHour: Bool?
}

