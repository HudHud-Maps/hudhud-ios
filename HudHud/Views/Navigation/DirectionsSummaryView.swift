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
                    .font(.system(.largeTitle))
                    .fontWeight(.semibold)
                    .lineLimit(1)
                // distance • type of route
                Text("\(self.formatter.formatDistance(distance: self.directionPreviewData.distance)) • \(self.directionPreviewData.typeOfRoute)", comment: "distance • type of route")
                    .font(.system(.body))
                    .lineLimit(1)
            }
            Spacer()
            // Go button
            Button {
                self.go()
            } label: {
                Text("Go", comment: "start navigation")
                    .font(.system(.title2))
                    .bold()
                    .lineLimit(1)
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
