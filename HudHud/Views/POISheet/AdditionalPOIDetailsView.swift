//
//  AdditionalPOIDetailsView.swift
//  HudHud
//
//  Created by Alaa . on 02/05/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import CoreLocation
import SwiftUI

struct AdditionalPOIDetailsView: View {
    let item: ResolvedItem
    let routes: Toursprung.RouteCalculationResult?
    var formatter = Formatters()

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text("Hours")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if let isOpen = self.item.isOpen {
                    Text("\(isOpen ? "Open" : "Closed")")
                        .font(.body.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(isOpen ? .blue : .red)
                } else {
                    Text("Unknown")
                        .font(.body.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .frame(maxWidth: .infinity)
            Divider()
            VStack(alignment: .leading) {
                Text("Distance")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if let route = routes?.routes.first {
                    Text("\(self.formatter.formatDistance(distance: route.distance))")
                        .font(.body.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                } else {
                    Text("N/A")
                        .font(.body.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .frame(maxWidth: .infinity)
            Divider()
            VStack(alignment: .leading) {
                Text("Duration")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if let route = routes?.routes.first {
                    Text("\(self.formatter.formatDuration(duration: route.expectedTravelTime))")
                        .font(.body.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                } else {
                    Text("N/A")
                        .font(.body.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .frame(maxWidth: .infinity)
            Divider()
            VStack(alignment: .leading) {
                Text("Ratings")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if let rating = self.item.rating {
                    HStack(spacing: 1) {
                        Image(systemSymbol: .starFill)
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("\(rating, specifier: "%.1f")")
                            .font(.body.bold())
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        Text("(\(self.item.ratingsCount ?? 0))")
                            .font(.body.bold())
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("No Ratings")
                        .font(.body.bold())
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

@available(iOS 17, *)
#Preview(traits: .sizeThatFitsLayout) {
    let searchViewStore: SearchViewStore = .storeSetUpForPreviewing
    searchViewStore.mapStore.selectedItem = ResolvedItem(id: UUID().uuidString, title: "Nozomi", subtitle: "7448 King Fahad Rd, Al Olaya, 4255, Riyadh 12331", category: "Restaurant", type: .toursprung, coordinate: CLLocationCoordinate2D(latitude: 24.732211928084162, longitude: 46.87863163915118), color: Color(.systemRed), rating: 4.4, ratingsCount: 230, isOpen: true)
    return ContentView(searchStore: searchViewStore)
}
