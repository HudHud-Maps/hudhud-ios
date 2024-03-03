//
//  TrafficChartView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 27/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//
import SwiftUI
import Charts
struct TrafficChartView: View {
	let chartData: chartData
	var body: some View {
		Chart(chartData.getSpecificTraficRange) { shape in
			BarMark(
				x: .value("Hours Range", shape.hour,unit: .hour),
				y: .value("Occupancy Range", shape.trafficRange * 100), width: .inset(40)
			)
			.foregroundStyle(
				shape.currentHour ?? false ? Color(
					UIColor.systemBlue
				) : Color(
					UIColor.secondarySystemFill
				)
			)
			RuleMark(
				y: .value(
					"usualOccupancy",
					chartData.usualOccupancy * 100
				)
			)
			.foregroundStyle(
				.orange
			)
			.annotation(
				position: .top,
				alignment: .bottomLeading
			) {
				Text("\((chartData.usualOccupancyTime.formatted())) min")
			}
		}
		.chartYAxis(.hidden)
		.chartXAxis(content: {
			AxisMarks(values: AxisMarkValues.stride(by: .hour,count: 3)) { _ in
				AxisValueLabel(format: .dateTime.hour(), centered: true)
			}
		})
	}
}
#Preview {
	let data = chartData(
		usualOccupancy: 0.8,
		usualOccupancyTime: 60,
		timeStart:13,
		timeEnd: 23
	)
	return TrafficChartView(chartData: data)
		.padding(.vertical,300)
		.padding(.horizontal,2)
}
