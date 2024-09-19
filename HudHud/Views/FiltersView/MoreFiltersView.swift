//
//  MoreFiltersView.swift
//  HudHud
//
//  Created by Alaa . on 05/09/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SFSafeSymbols
import SwiftUI

struct MoreFiltersView: View {

    // MARK: Properties

    @ObservedObject var searchStore: SearchViewStore
    @ObservedObject var filterStore: FilterStore

    @Environment(\.dismiss) private var dismiss

    // MARK: Content

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button {
                    self.filterStore.resetFilters()
                    self.dismiss()
                } label: {
                    Text("Cancel")
                        .hudhudFont(size: 16, fontWeight: .medium)
                        .foregroundStyle(Color.Colors.General._02Grey)
                }
                Spacer()
                Text("Filters")
                    .hudhudFont(.headline)
                    .foregroundStyle(Color.Colors.General._01Black)
                Spacer()
                Button {
                    self.filterStore.applyFilters()
                    self.dismiss()
                } label: {
                    Text("Apply")
                        .hudhudFont().bold()
                        .foregroundStyle(Color.Colors.General._07BlueMain)
                }
            }
            .padding(.vertical)
            // Sort By Filter
            Text("Sort By")
            HudhudSegmentedPicker(
                selected: self.$filterStore.sortSelection,
                options: [
                    SegmentOption(value: FilterStore.FilterType.SortOption.relevance, label: .text(FilterStore.FilterType.SortOption.relevance.stringValue)),
                    SegmentOption(value: FilterStore.FilterType.SortOption.distance, label: .text(FilterStore.FilterType.SortOption.distance.stringValue))
                ]
            )
            .padding(.bottom)

            // Price Filter
            Text("Price")
            HudhudSegmentedPicker(
                selected: self.$filterStore.priceSelection,
                options: [
                    SegmentOption(value: FilterStore.FilterType.PriceRange.cheap, label: .text(FilterStore.FilterType.PriceRange.cheap.stringValue)),
                    SegmentOption(value: FilterStore.FilterType.PriceRange.medium, label: .text(FilterStore.FilterType.PriceRange.medium.stringValue)),
                    SegmentOption(value: FilterStore.FilterType.PriceRange.pricy, label: .text(FilterStore.FilterType.PriceRange.pricy.stringValue)),
                    SegmentOption(value: FilterStore.FilterType.PriceRange.expensive, label: .text(FilterStore.FilterType.PriceRange.expensive.stringValue))
                ]
            )
            .padding(.bottom)

            // Rating Filter
            Text("Rating")
            HudhudSegmentedPicker(
                selected: self.$filterStore.ratingSelection,
                options: [
                    SegmentOption(value: FilterStore.FilterType.RatingOption.anyRating, label: .text(FilterStore.FilterType.RatingOption.anyRating.stringValue)),
                    SegmentOption(value: FilterStore.FilterType.RatingOption.rating3andHalf, label: .textWithSymbol(FilterStore.FilterType.RatingOption.rating3andHalf.stringValue, .starFill)),
                    SegmentOption(value: FilterStore.FilterType.RatingOption.rating4, label: .textWithSymbol(FilterStore.FilterType.RatingOption.rating4.stringValue, .starFill)),
                    SegmentOption(value: FilterStore.FilterType.RatingOption.rating4andHalf, label: .textWithSymbol(FilterStore.FilterType.RatingOption.rating4andHalf.stringValue, .starFill))
                ]
            )
            .padding(.bottom)

            // Schedule Filter
            Text("Work Schedule")
            HudhudSegmentedPicker(
                selected: self.$filterStore.scheduleSelection,
                options: [
                    SegmentOption(value: FilterStore.FilterType.ScheduleOption.any, label: .text(FilterStore.FilterType.ScheduleOption.any.stringValue)),
                    SegmentOption(value: FilterStore.FilterType.ScheduleOption.open, label: .text(FilterStore.FilterType.ScheduleOption.open.stringValue)),
                    SegmentOption(value: FilterStore.FilterType.ScheduleOption.custom, label: .text(FilterStore.FilterType.ScheduleOption.custom.stringValue))
                ]
            )
            Spacer()
            Divider().padding(-20)
            Button {
                self.filterStore.sortSelection = .relevance
                self.filterStore.priceSelection = .cheap
                self.filterStore.ratingSelection = .anyRating
                self.filterStore.scheduleSelection = .any
            } label: {
                Text("Reset")
                    .hudhudFont(.headline)
                    .foregroundStyle(Color.Colors.General._12Red)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .padding(.horizontal, 5)
        .onAppear {
            self.filterStore.saveCurrentFilters()
        }
    }
}

#Preview {
    return MoreFiltersView(searchStore: .storeSetUpForPreviewing, filterStore: .storeSetUpForPreviewing)
}
