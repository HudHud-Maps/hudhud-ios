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
    var formatter = Formatters()

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                // 20 min AKA duration
                Text("\(self.formatter.formatDuration(duration: self.directionPreviewData.duration))", comment: "duration")
                    .hudhudFont(.title)
                    .lineLimit(1)
                HStack {
                    // distance • type of route
                    Text("\(self.formatter.formatDistance(distance: self.directionPreviewData.distance))")
                        .hudhudFont(.headline)
                    Text("•")
                    Text("\(self.directionPreviewData.typeOfRoute)", comment: "distance • type of route").hudhudFont(.headline)
                }
                .foregroundColor(Color(.Colors.General._02Grey))
                .lineLimit(1)
            }
            Spacer()
            // Go button
            Button {
                self.go()
            } label: {
                Text("Go", comment: "start navigation")
                    .hudhudFont(.title2)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .lineLimit(1)
                    .foregroundStyle(Color(.Colors.General._05WhiteBackground))
                    .background(Color(.Colors.General._07BlueMain))
                    .background(.blue)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity)
        .cornerRadius(8)
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
