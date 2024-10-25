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
                options: self.filterStore.sortOptions
            )

            .padding(.bottom)

            // Price Filter
            Text("Price")
            HudhudSegmentedPicker(
                selected: self.$filterStore.priceSelection,
                options: self.filterStore.priceOptions
            )
            .padding(.bottom)

            // Rating Filter
            Text("Rating")
            HudhudSegmentedPicker(
                selected: self.$filterStore.ratingSelection,
                options: self.filterStore.ratingOptions
            )
            .padding(.bottom)

            // Schedule Filter
            Text("Work Schedule")
            HudhudSegmentedPicker(
                selected: self.$filterStore.scheduleSelection,
                options: self.filterStore.scheduleOptions
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

//
// #Preview {
//    return MoreFiltersView(searchStore: .storeSetUpForPreviewing, filterStore: .storeSetUpForPreviewing)
// }
