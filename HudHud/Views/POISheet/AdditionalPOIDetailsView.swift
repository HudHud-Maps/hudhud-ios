//
//  AdditionalPOIDetailsView.swift
//  HudHud
//
//  Created by Alaa . on 02/05/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import CoreLocation
import FerrostarCoreFFI
import SwiftUI

struct AdditionalPOIDetailsView: View {

    // MARK: Properties

    let item: ResolvedItem
    let routes: [Route]?
    var formatter = Formatters()

    // MARK: Content

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text("Hours")
                    .hudhudFont(.footnote)
                    .foregroundStyle(Color.Colors.General._02Grey)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if let isOpen = self.item.isOpen {
                    Text("\(isOpen ? "Open" : "Closed")")
                        .hudhudFont(.subheadline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(isOpen ? Color(.Colors.General._07BlueMain) : Color(.Colors.General._12Red))
                } else {
                    Text("Unknown")
                        .hudhudFont(.headline)
                        .foregroundStyle(Color.Colors.General._01Black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.trailing, 6)
            Divider().foregroundStyle(Color.Colors.General._04GreyForLines).frame(height: 25).padding(.top, 8)
            VStack(alignment: .leading) {
                Text("Distance")
                    .hudhudFont(.footnote)
                    .foregroundStyle(Color.Colors.General._02Grey)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if let routes, let route = routes.first {
                    Text("\(self.formatter.formatDistance(distance: route.distance))")
                        .hudhudFont(.headline)
                        .foregroundStyle(Color.Colors.General._01Black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                } else {
                    Text("N / A")
                        .hudhudFont(.headline)
                        .foregroundStyle(Color.Colors.General._01Black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 6)
            Divider().foregroundStyle(Color.Colors.General._04GreyForLines).frame(height: 25).padding(.top, 8)
            VStack(alignment: .leading) {
                Text("Duration")
                    .hudhudFont(.footnote)
                    .foregroundStyle(Color.Colors.General._02Grey)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if let routes, let route = routes.first {
                    Text("\(self.formatter.formatDuration(duration: route.duration))")
                        .hudhudFont(.headline)
                        .foregroundStyle(Color.Colors.General._01Black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                } else {
                    Text("N / A")
                        .hudhudFont(.headline)
                        .foregroundStyle(Color.Colors.General._01Black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 6)
            Divider().foregroundStyle(Color.Colors.General._04GreyForLines).frame(height: 25).padding(.top, 8)
            VStack(alignment: .leading) {
                Text("Ratings")
                    .hudhudFont(.footnote)
                    .foregroundStyle(Color.Colors.General._02Grey)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if let rating = self.item.rating {
                    HStack(spacing: 1) {
                        Image(systemSymbol: .starFill)
                            .font(.caption)
                            .foregroundColor(.Colors.General._13Orange)
                        Text("\(rating, specifier: "%.1f")")
                            .hudhudFont(.headline)
                            .foregroundStyle(Color.Colors.General._01Black)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        Text("(\(self.item.ratingsCount ?? 0))")
                            .hudhudFont(.headline)
                            .foregroundStyle(Color.Colors.General._02Grey)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("No Ratings")
                        .hudhudFont(.headline)
                        .foregroundStyle(Color.Colors.General._01Black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .padding(.leading, 6)
            Spacer()
                .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    VStack {
        AdditionalPOIDetailsView(item: .artwork, routes: nil)
    }
}

// #Preview(traits: .sizeThatFitsLayout) {
//    let searchViewStore: SearchViewStore = .storeSetUpForPreviewing
//    searchViewStore.mapStore.select(.ketchup)
//    return ContentView(
//        store: .init(
//            mapStore: .storeSetUpForPreviewing,
//            sheetStore: .storeSetUpForPreviewing,
//            mapViewStore: .storeSetUpForPreviewing,
//            searchViewStore: searchViewStore,
//            userLocationStore: .storeSetUpForPreviewing,
//            navigationEngine: .init(),
//            mapContainerViewStore: MapViewContainerStore(
//                navigationVisualization: .init(
//                    navigationEngine: .init(),
//                    routePlanner: RoutePlanner(routingService: GraphHopperRouteProvider())
//                )
//            )
//        )
//    )
// }
