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
    let item: ResolvedItem
    let routes: Toursprung.RouteCalculationResult?
    var formatter = Formatters()

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text("Hours")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if let isOpen = self.item.isOpen {
                    Text("\(isOpen ? "Open" : "Closed")")
                        .bold()
                        .font(.title3)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(isOpen ? .blue : .red)
                } else {
                    Text("Unknown")
                        .bold()
                        .font(.title3)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .frame(maxWidth: .infinity)
            Divider()
            VStack(alignment: .leading) {
                Text("Distance")
                    .font(.body)
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
                    Text("")
                        .bold()
                        .font(.title3)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .frame(maxWidth: .infinity)
            Divider()
            VStack(alignment: .leading) {
                Text("Duration")
                    .font(.body)
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
                    Text("")
                        .bold()
                        .font(.title3)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .frame(maxWidth: .infinity)
            Divider()
            VStack(alignment: .leading) {
                Text("Ratings")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if let rating = self.item.rating {
                    Text("\(rating)")
                        .bold()
                        .font(.title3)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                } else {
                    Text("No Ratings")
                        .bold()
                        .font(.title3)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            Spacer()
                .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    return VStack {
        AdditionalPOIDetailsView(item: .artwork, routes: .none)
    }
}
