//
//  SearchSheet.swift
//  HudHud
//
//  Created by Patrick Kladek on 01.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import Foundation
import MapboxCoreNavigation
import MapboxDirections
import MapboxNavigation
import MapKit
import MapLibre
import MapLibreSwiftUI
import OSLog
import SwiftLocation
import SwiftUI

// MARK: - SearchSheet

struct SearchSheet: View {

    @ObservedObject var mapStore: MapStore
    @ObservedObject var searchStore: SearchViewStore
    @ObservedObject var trendingStore: TrendingStore
    @FocusState private var searchIsFocused: Bool
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            HStack(spacing: 0) {
                HStack {
                    Image(systemSymbol: .magnifyingglass)
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 8)
                    TextField("Search", text: self.$searchStore.searchText)
                        .focused(self.$searchIsFocused)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 0)
                        .autocorrectionDisabled()
                        .overlay(
                            HStack {
                                Spacer()
                                if !self.searchStore.searchText.isEmpty {
                                    Button {
                                        self.searchStore.searchText = ""
                                    } label: {
                                        Image(systemSymbol: .multiplyCircleFill)
                                            .foregroundColor(.gray)
                                            .frame(minWidth: 44, minHeight: 44)
                                    }
                                }
                            }
                        )
                        .padding(.horizontal, 10)
                }
                switch self.searchStore.searchType {
                case .returnPOILocation, .favorites:
                    Button("Cancel") {
                        self.dismiss()
                    }
                    .foregroundColor(.gray)
                    .padding(.trailing)
                case .selectPOI, .categories:
                    EmptyView()
                }
            }
            .background(.quinary)
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.top)
            List {
                if !self.searchStore.searchText.isEmpty {
                    if self.searchStore.isSheetLoading {
                        ForEach(SearchSheet.fakeData.indices, id: \.self) { item in
                            Button(action: {},
                                   label: {
                                       SearchSheet.fakeData[item]
                                           .frame(maxWidth: .infinity)
                                   })
                                   .redacted(reason: .placeholder)
                                   .disabled(true)
                                   .listRowSeparator(.hidden)
                                   .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 2, trailing: 8))
                        }
                    } else {
                        ForEach(self.mapStore.displayableItems) { item in
                            switch item {
                            case let .categoryItem(categoryItem):
                                CategoryItemView(item: categoryItem)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                    .listRowSpacing(0)
                            case .predictionItem, .category, .resolvedItem:
                                Button {
                                    Task {
                                        self.searchIsFocused = false
                                        await self.searchStore.didSelect(item)
                                        if let resolvedItem = mapStore.selectedItem {
                                            self.storeRecent(item: resolvedItem)
                                        }
                                        switch self.searchStore.searchType {
                                        case let .returnPOILocation(completion):
                                            if let selectedItem = self.mapStore.selectedItem {
                                                completion?(.waypoint(selectedItem))
                                                self.dismiss()
                                            }
                                        case .selectPOI, .categories, .favorites:
                                            break
                                        }
                                    }
                                } label: {
                                    SearchResultItemView(item: SearchResultItem(item), searchText: nil)
                                        .frame(maxWidth: .infinity)
                                        .redacted(reason: self.searchStore.isSheetLoading ? .placeholder : [])
                                }
                                .disabled(self.searchStore.isSheetLoading)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 2, trailing: 8))
                            }
                        }
                        .listStyle(.plain)
                        if self.mapStore.displayableItems.isEmpty {
                            let label = self.searchStore.searchError?.localizedDescription != nil ? "Search Error" : "No results"
                            backport.contentUnavailable(label: label, SFSymbol: .magnifyingglass, description: self.searchStore.searchError?.localizedDescription ?? "No results for \(self.searchStore.searchText) were found.").padding(.vertical, 50)
                                .listRowSeparator(.hidden)
                        }
                    }
                } else {
                    if self.searchStore.searchType != .favorites {
                        SearchSectionView(title: "Favorites") {
                            FavoriteCategoriesView(mapStore: self.mapStore, searchStore: self.searchStore)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 8))
                        .listRowSeparator(.hidden)
                    }

                    if let trendingPOIs = self.trendingStore.trendingPOIs, !trendingPOIs.isEmpty {
                        SearchSectionView(title: "Nearby Trending") {
                            PoiTileGridView(trendingPOIs: self.trendingStore)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 8))
                        .listRowSeparator(.hidden)
                    }
                    SearchSectionView(title: "Recents") {
                        RecentSearchResultsView(mapStore: self.mapStore, searchStore: self.searchStore, searchType: self.searchStore.searchType)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 8))
                    .listRowSeparator(.hidden)
                }
            }
            .scrollIndicators(.hidden)
            .listStyle(.plain)
        }
    }

    // MARK: - Lifecycle

    init(mapStore: MapStore, searchStore: SearchViewStore, trendingStore: TrendingStore) {
        self.mapStore = mapStore
        self.searchStore = searchStore
        self.trendingStore = trendingStore
        self.searchIsFocused = false
    }

    // MARK: - Internal

    func storeRecent(item: ResolvedItem) {
        withAnimation {
            self.searchStore.storeInRecent(item)
        }
    }

    func dismissSheet() {
        self.mapStore.selectedItem = nil // Set selectedItem to nil to dismiss the sheet
    }
}

extension Route: Identifiable {}

extension SearchSheet {
    static var fakeData = [
        SearchResultItemView(item: SearchResultItem(DisplayableRow.starbucks), searchText: nil),
        SearchResultItemView(item: SearchResultItem(DisplayableRow.ketchup), searchText: nil),
        SearchResultItemView(item: SearchResultItem(DisplayableRow.supermarket), searchText: nil),
        SearchResultItemView(item: SearchResultItem(DisplayableRow.publicPlace), searchText: nil),
        SearchResultItemView(item: SearchResultItem(DisplayableRow.artwork), searchText: nil),
        SearchResultItemView(item: SearchResultItem(DisplayableRow.pharmacy), searchText: nil)
    ]
}

// MARK: - RawRepresentable + RawRepresentable

extension [ResolvedItem]: RawRepresentable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder()
                  .decode([ResolvedItem].self, from: data) else {
            return nil
        }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self) else {
            return "[]"
        }
        let result = String(decoding: data, as: UTF8.self)
        return result
    }
}

#Preview {
    let searchViewStore: SearchViewStore = .storeSetUpForPreviewing
    let trendingStroe = TrendingStore()
    return SearchSheet(mapStore: searchViewStore.mapStore, searchStore: searchViewStore, trendingStore: trendingStroe)
}
