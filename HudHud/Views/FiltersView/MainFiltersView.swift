//
//  MainFiltersView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 19/08/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct MainFiltersView: View {

    // MARK: Properties

    @ObservedObject var searchStore: SearchViewStore
    @ObservedObject var filterStore: FilterStore

    @State var showMoreFilterView: Bool = false

    // MARK: Content

    var body: some View {
        HStack(spacing: 10) {
            self.filterButton(title: "Open Now", filter: .openNow)
            self.filterButton(title: "Top Rated", filter: .topRated)
            Spacer()
            Button {
                self.showMoreFilterView = true
            } label: {
                Image(.filter)
                    .hudhudFont(.caption2)
                    .scaledToFit()
            }
        }
        .sheet(isPresented: self.$showMoreFilterView) {
            MoreFiltersView(searchStore: self.searchStore, filterStore: self.filterStore)
                .presentationDragIndicator(.visible)
        }
    }

    private func filterButton(title: String, filter: FilterStore.FilterType) -> some View {
        Button {
            self.filterStore.applyFilters(filter)
        } label: {
            Text(title)
                .hudhudFont(size: 12, fontWeight: .semiBold)
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .foregroundStyle(self.filterStore.selectedFilters.contains(filter) ? Color(.Colors.General._10GreenMain) : Color(.Colors.General._01Black))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(self.filterStore.selectedFilters.contains(filter) ? Color(.Colors.General._10GreenMain) : Color(.Colors.General._04GreyForLines), lineWidth: 1)
                )
        }
    }
}

#Preview {
    return MainFiltersView(searchStore: .storeSetUpForPreviewing, filterStore: .storeSetUpForPreviewing)
}
