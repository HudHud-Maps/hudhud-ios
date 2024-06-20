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
    @FocusState private var searchIsFocused: Bool
    @Environment(\.dismiss) var dismiss

    var body: some View {
        return VStack {
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
                                    Button(action: {
                                        self.searchStore.searchText = ""
                                    }, label: {
                                        Image(systemSymbol: .multiplyCircleFill)
                                            .foregroundColor(.gray)
                                            .padding(.vertical)
                                    })
                                }
                            }
                        )
                        .padding(.horizontal, 10)
                }
                switch self.searchStore.searchType {
                case .returnPOILocation:
                    Button("Cancel", action: {
                        self.dismiss()
                    })
                    .foregroundColor(.gray)
                    .padding(.trailing)
                case .selectPOI:
                    EmptyView()
                }
            }
            .background(.quinary)
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.top)
            List {
                if !self.searchStore.searchText.isEmpty {
                    if self.searchStore.isSearching {
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
                            Button(action: {
                                Task {
                                    if let resolvedItem = item.innerModel as? ResolvedItem {
                                        self.mapStore.selectedItem = resolvedItem
                                        self.storeRecent(item: resolvedItem)
                                    } else {
                                        let resolvedItems = try await self.searchStore.resolve(item: item)

                                        if resolvedItems.count == 1, let firstItem = resolvedItems.first, let resolvedItem = firstItem.innerModel as? ResolvedItem {
                                            self.mapStore.selectedItem = resolvedItem
                                            self.storeRecent(item: resolvedItem)

                                            let index = self.mapStore.displayableItems.firstIndex { itemInArray in
                                                return itemInArray.id == resolvedItem.id
                                            }

                                            if let index {
                                                self.mapStore.displayableItems[index] = AnyDisplayableAsRow(resolvedItem)
                                            } else {
                                                Logger.searchView.error("Resolved an item that is no longer in the displayable list")
                                            }

                                        } else {
                                            self.mapStore.displayableItems = resolvedItems
                                        }
                                    }
                                    switch self.searchStore.searchType {
                                    case let .returnPOILocation(completion):
                                        if let selectedItem = self.mapStore.selectedItem {
                                            completion?(.waypoint(selectedItem))
                                            self.dismiss()
                                        }
                                    case .selectPOI:
                                        break
                                    }

                                    self.searchIsFocused = false
                                }

                            }, label: {
                                SearchResultItem(prediction: item, searchText: self.$searchStore.searchText)
                                    .frame(maxWidth: .infinity)
                                    .redacted(reason: self.searchStore.isSearching ? .placeholder : [])
                            })
                            .disabled(self.searchStore.isSearching)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 2, trailing: 8))
                        }
                        .listStyle(.plain)
                    }
                } else {
                    SearchSectionView(title: "Favorites") {
                        FavoriteCategoriesView(mapStore: self.mapStore, searchStore: self.searchStore)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 8))
                    .listRowSeparator(.hidden)

                    SearchSectionView(title: "Recents") {
                        RecentSearchResultsView(mapStore: self.mapStore, searchStore: self.searchStore)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 8))
                    .listRowSeparator(.hidden)
                }
            }

            .listRowSeparator(.hidden)
            .scrollIndicators(.hidden)
            .listStyle(.plain)
        }
    }

    // MARK: - Lifecycle

    init(mapStore: MapStore, searchStore: SearchViewStore) {
        self.mapStore = mapStore
        self.searchStore = searchStore
        self.searchIsFocused = false
    }

    // MARK: - Internal

    func storeRecent(item: ResolvedItem) {
        withAnimation {
            if self.searchStore.recentViewedItem.count > 9 {
                self.searchStore.recentViewedItem.removeLast()
            }
            if self.searchStore.recentViewedItem.contains(item) {
                self.searchStore.recentViewedItem.removeAll(where: { $0 == item })
            }
            self.searchStore.recentViewedItem.append(item)
        }
    }

    func dismissSheet() {
        self.mapStore.selectedItem = nil // Set selectedItem to nil to dismiss the sheet
    }
}

extension Route: Identifiable {}

extension SearchSheet {
    static var fakeData = [
        SearchResultItem(prediction: PredictionItem.starbucks, searchText: nil),
        SearchResultItem(prediction: PredictionItem.supermarket, searchText: nil),
        SearchResultItem(prediction: PredictionItem.pharmacy, searchText: nil),
        SearchResultItem(prediction: PredictionItem.artwork, searchText: nil),
        SearchResultItem(prediction: PredictionItem.ketchup, searchText: nil),
        SearchResultItem(prediction: PredictionItem.publicPlace, searchText: nil)
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
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return result
    }
}

#Preview {
    let searchViewStore: SearchViewStore = .storeSetUpForPreviewing
    return SearchSheet(mapStore: searchViewStore.mapStore, searchStore: searchViewStore)
}
