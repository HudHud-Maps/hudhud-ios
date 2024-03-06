//
//  TrafficChartView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 27/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//
import SwiftUI
import Charts
import SFSafeSymbols

struct TrafficChartView: View {
	let chartData: TrafficChartData
	var body: some View {
		if let trafficRange = chartData.getSpecificTrafficRange {
			Chart(trafficRange) { shape in
				BarMark(
					x: .value("Hours Range", shape.hour.lowerBound, unit: .hour),
					y: .value("Occupancy Range", shape.traffic), width: .automatic
				)
				.foregroundStyle(
					shape.hour.contains(Date()) == true ? .blue
					: Color(
						UIColor.secondarySystemFill
					)
				)
			}
			.chartXAxis(content: {
				AxisMarks(preset: .aligned, values: AxisMarkValues.stride(by: .hour,
														count: 3)) { _ in
					AxisGridLine()
					AxisValueLabel(format: .dateTime.hour())
				}
			})
			.chartYAxis {
				AxisMarks(preset: .automatic, position: .automatic, values: [0]) { _ in
					AxisGridLine()
				}
			}
			.chartYScale(domain: 0...1)
		} else {
			Label("Bad Traffic Data", systemImage: "exclamationmark.triangle")
		}
	}
}
#Preview {
	VStack(alignment: .leading) {
		Text("Traffic")
			.font(.title)
			.frame(width: .infinity)
		TrafficChartView(chartData: TrafficChartData(date: Date(), traffic: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0.1, 0, 0.1, 0.1, 0.2, 0.4, 0.9, 0.9, 0.8, 0.8, 0.6, 0.4, 0.0, 0.0, 0.0]))
			.frame(maxHeight: 200)
			
		Spacer()
	}
	.padding()

}
