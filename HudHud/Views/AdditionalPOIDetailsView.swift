//
//  AdditionalPOIDetailsView.swift
//  HudHud
//
//  Created by Alaa . on 02/05/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import SwiftUI

struct AdditionalPOIDetailsView: View {
    let routes: Toursprung.RouteCalculationResult?
    var formatter = Formatters()

    var body: some View {
        // HSTACk - 4 VSTACK - Distance - duration
        HStack {
            VStack {
                Text("Hours")
                    .foregroundStyle(.secondary)
                Text("Unknown")
                    .hudhudFont(size: 16, fontWeight: .semiBold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            Divider()
            VStack {
                Text("Distance")
                    .foregroundStyle(.secondary)
                if let route = routes?.routes.first {
                    Text("\(self.formatter.formatDistance(distance: route.distance))")
                        .hudhudFont(size: 16, fontWeight: .semiBold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                } else {
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            Divider()
            VStack {
                Text("Duration")
                    .foregroundStyle(.secondary)
                if let route = routes?.routes.first {
                    Text("\(self.formatter.formatDuration(duration: route.expectedTravelTime))")
                        .hudhudFont(size: 16, fontWeight: .semiBold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                } else {
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            Divider()
            VStack {
                Text("Ratings")
                    .foregroundStyle(.secondary)
                Text("No Ratings")
                    .hudhudFont(size: 16, fontWeight: .semiBold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 6)
    }
}
