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
        HStack {
            VStack(alignment: .leading) {
                Text("Hours")
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text("Unknown")
                    .bold()
                    .font(.title3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity)
            Divider()
            VStack(alignment: .leading) {
                Text("Distance")
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if let route = routes?.routes.first {
                    Text("\(self.formatter.formatDistance(distance: route.distance))")
                        .bold()
                        .font(.title3)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                } else {
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            Divider()
            VStack(alignment: .leading) {
                Text("Duration")
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if let route = routes?.routes.first {
                    Text("\(self.formatter.formatDuration(duration: route.expectedTravelTime))")
                        .bold()
                        .font(.title3)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                } else {
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            Divider()
            VStack(alignment: .leading) {
                Text("Ratings")
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text("No Ratings")
                    .bold()
                    .font(.title3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            Spacer()
                .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    return VStack {
        AdditionalPOIDetailsView(routes: .none)
    }
}
