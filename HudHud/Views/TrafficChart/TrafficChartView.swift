//
//  TrafficChartView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 27/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Charts
import SFSafeSymbols
import SwiftUI

struct TrafficChartView: View {

    // MARK: Properties

    let chartData: TrafficChartData

    // MARK: Content

    var body: some View {
        if let trafficRange = chartData.getSpecificTrafficRange {
            Chart(trafficRange) { shape in
                BarMark(
                    x: .value(String(localized: "Hours Range", comment: "traffic chart view, Hours range x axes"), shape.hour.lowerBound, unit: .hour),
                    y: .value(String(localized: "Occupancy Range", comment: "traffic chart view, Occupancy Range y axes"), shape.traffic), width: .automatic
                )
                .foregroundStyle(
                    shape.hour.contains(Date()) == true ? .blue
                        : Color(
                            UIColor.secondarySystemFill
                        )
                )
            }
            .chartXAxis(content: {
                AxisMarks(preset: .aligned, values: AxisMarkValues.stride(by: .hour, count: 3)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.hour())
                }
            })
            .chartYAxis {
                AxisMarks(preset: .automatic, position: .automatic, values: [0]) { _ in
                    AxisGridLine()
                }
            }
            .chartYScale(domain: 0 ... 1)
        } else {
            Label {
                Text("Bad Traffic Data", comment: "for traffic chart")
            } icon: {
                Image(systemSymbol: .exclamationmarkTriangle)
            }
        }
    }
}

#Preview {
    let trafic = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0.1, 0, 0.1, 0.1, 0.2, 0.4, 0.9, 0.9, 0.8, 0.8, 0.6, 0.4, 0.0, 0.0, 0.0]

    return VStack(alignment: .leading) {
        Text("Traffic")
            .hudhudFont(.title)
            .frame(width: .infinity)
        TrafficChartView(chartData: TrafficChartData(date: Date(), traffic: trafic))
            .frame(maxHeight: 200)

        Spacer()
    }
    .padding()
}
