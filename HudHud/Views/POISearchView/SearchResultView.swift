//
//  SearchResultView.swift
//  HudHud
//
//  Created by Naif Alrashed on 29/07/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import SwiftUI

// MARK: - SearchResultView

struct SearchResultView: View {

    // MARK: Properties

    @ObservedObject var favoritesStore = FavoritesStore()
    let item: ResolvedItem
    let directions: () -> Void
    var formatter = Formatters()
    @Environment(\.openURL) var openURL

    // MARK: Content

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            VStack(alignment: .leading, spacing: 7) {
                Text(self.item.title)
                    .hudhudFont(.headline)
                    .foregroundStyle(Color.Colors.General._01Black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    if let rating = item.rating, let ratingsCount = item.ratingsCount {
                        RatingView(ratingStore: RatingStore(staticRating: rating,
                                                            ratingsCount: ratingsCount))
                    }
                    if let priceRange = item.priceRange, let priceIcon = HudHudPOI.PriceRange(rawValue: priceRange) {
                        Text("•")
                        Text("\(priceIcon.displayValue)")
                            .hudhudFont(.subheadline)
                    }
                    Spacer()
                }
                .foregroundStyle(Color.Colors.General._02Grey)
                HStack {
                    if self.item.isOpen ?? false {
                        Text("Open")
                            .hudhudFont(.caption)
                            .foregroundStyle(Color.Colors.General._06DarkGreen)
                        Text("•")
                    }
                    Text(self.item.category ?? "")
                    if self.item.distance != nil || self.item.driveDuration != nil {
                        let durationText = self.item.driveDuration.map { self.formatter.formatDuration(duration: $0) }
                        let distanceText = self.item.distance.map { "(\(self.formatter.formatDistance(distance: $0)))" }
                        HStack {
                            Text("•")
                            Image(systemSymbol: .carFill)
                            Text("\([durationText, distanceText].compactMap(\.self).joined(separator: " "))")
                        }
                    }
                    Spacer()
                }
                .hudhudFont(.caption)
                .foregroundStyle(Color.Colors.General._02Grey)
            }
            .padding(.bottom)
            .padding(.horizontal)
            if !self.item.mediaURLs.isEmpty {
                POIMediaView(mediaURLs: self.item.mediaURLs)
                    .padding(.top, 9)
                    .padding(.bottom, 16)
            }
            POIBottomToolbar(item: self.item, directions: self.directions)
                .padding(.bottom, 10)
                .padding(.leading, 10)
        }
        .padding(.top)
    }
}

// MARK: - RatingView

struct RatingView: View {

    // MARK: Properties

    let ratingStore: RatingStore

    // MARK: Content

    var body: some View {
        HStack(spacing: 4) {
            Text("\(self.ratingStore.state.staticRating, specifier: "%.1f")")
                .hudhudFont(.subheadline)
                .foregroundStyle(Color.Colors.General._01Black)

            self.starView(for: self.ratingStore.state.staticRating)
        }
    }
}

// MARK: - Private

private extension RatingView {

    @ViewBuilder
    func starView(for rating: Double) -> some View {
        HStack(spacing: 4) {
            ForEach(1 ... 5, id: \.self) { index in
                Image(rating < Double(index) ? .starOff : .starOn)
                    .resizable()
                    .frame(width: 16, height: 16)
            }
        }
    }
}

#Preview {
    SearchResultView(item: .ketchup) {}
}
