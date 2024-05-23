//
//  SearchSheet.swift
//  HudHud
//
//  Created by Patrick Kladek on 01.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import MapboxCoreNavigation
import MapboxDirections
import MapboxNavigation
import MapKit
import MapLibre
import MapLibreSwiftUI
import OSLog
import POIService
import SwiftLocation
import SwiftUI

// MARK: - SearchSheet

struct SearchSheet: View {

    @ObservedObject var mapStore: MapStore
    @ObservedObject var searchStore: SearchViewStore
    @FocusState private var searchIsFocused: Bool
    @Environment(\.openURL) private var openURL
    @State private var isPresentWebView = false
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
            .padding()

            if !self.searchStore.searchText.isEmpty {
                if self.searchStore.isSearching {
                    List {
                        ForEach(SearchSheet.fakeData.indices, id: \.self) { item in
                            Button(action: {},
                                   label: {
                                       SearchSheet.fakeData[item]
                                           .frame(maxWidth: .infinity)
                                   })
                                   .redacted(reason: .placeholder)
                                   .disabled(true)
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 2, trailing: 8))
                    }
                    .listStyle(.plain)
                } else {
                    List(self.mapStore.displayableItems) { item in
                        Button(action: {
                            Task {
                                if let resolvedItem = item.innerModel as? ResolvedItem {
                                    self.mapStore.selectedItem = resolvedItem
                                } else {
                                    // Currently only ApplePOI supports resolving, so this should only be called on apple pois
                                    let resolvedItems = try await item.resolve(in: self.searchStore.apple)

                                    if resolvedItems.count == 1, let firstItem = resolvedItems.first, let resolvedItem = firstItem.innerModel as? ResolvedItem {
                                        self.mapStore.selectedItem = resolvedItem

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

                            self.searchStore.selectedDetent = .medium
                            self.searchIsFocused = false
                        }, label: {
                            SearchResultItem(prediction: item, searchViewStore: self.searchStore)
                                .frame(maxWidth: .infinity)
                                .redacted(reason: self.searchStore.isSearching ? .placeholder : [])
                        })
                        .disabled(self.searchStore.isSearching)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 2, trailing: 8))
                    }
                    .listStyle(.plain)
                }
            } else {
                List {
                    SearchSectionView(title: "Favorites") {
                        FavoriteCategoriesView(mapStore: self.mapStore, searchStore: self.searchStore)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 2, trailing: 8))
                    SearchSectionView(title: "Recents") {
                        ForEach(self.searchStore.recentViewedItem) { item in
                            RecentSearchResultsView(item: item, mapStore: self.mapStore, searchStore: self.searchStore)
                        }
                    }

                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 2, trailing: 8))
                    .padding(.top)
                }
                .listStyle(.plain)
            }
        }
        .backport.sheet(
            isPresented: Binding<Bool>(
                get: {
                    self.searchStore.searchType == .selectPOI
                        && self.mapStore.selectedItem != nil
                },
                set: { _ in
                    self.searchStore.selectedDetent = .medium
                    self.mapStore.selectedItem = nil
                }
            )
        ) {
            if let item = self.mapStore.selectedItem {
                POIDetailSheet(item: item) { calculation in
                    Logger.searchView.info("Start item \(item)")
                    self.searchStore.selectedDetent = .small
                    self.mapStore.routes = calculation
                    self.mapStore.displayableItems = [AnyDisplayableAsRow(item)]
                    if let location = calculation.waypoints.first {
                        self.mapStore.waypoints = [.myLocation(location), .waypoint(item)]
                    }
                } onMore: { action in
                    switch action {
                    case .phone:
                        // Perform phone action
                        if let phone = item.phone, let url = URL(string: "tel://\(phone)") {
                            self.openURL(url)
                        }
                        Logger.searchView.info("Item phone \(item.phone ?? "nil")")
                    case .website:
                        // Perform website action
                        self.isPresentWebView = true
                        Logger.searchView.info("Item website \(item.website?.absoluteString ?? "")")
                    case .moreInfo:
                        // Perform more info action
                        Logger.searchView.info("more item \(item))")
                    }
                } onDismiss: {
                    self.searchStore.mapStore.selectedItem = nil
                    self.searchStore.mapStore.displayableItems = []
                }
                .fullScreenCover(isPresented: self.$isPresentWebView) {
                    if let website = item.website {
                        SafariWebView(url: website)
                            .ignoresSafeArea()
                    }
                }
                .presentationDetents([.third, .large])
                .presentationBackgroundInteraction(
                    .enabled(upThrough: .third)
                )
                .interactiveDismissDisabled()
                .ignoresSafeArea()
                .onAppear {
                    // Store POI
                    self.storeRecent(item: item)
                    // update Sheet
                    self.searchStore.updateSheetDetent()
                }
            }
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
        SearchResultItem(prediction: PredictionItem.starbucks, searchViewStore: .storeSetUpForPreviewing),
        SearchResultItem(prediction: PredictionItem.supermarket, searchViewStore: .storeSetUpForPreviewing),
        SearchResultItem(prediction: PredictionItem.pharmacy, searchViewStore: .storeSetUpForPreviewing),
        SearchResultItem(prediction: PredictionItem.artwork, searchViewStore: .storeSetUpForPreviewing),
        SearchResultItem(prediction: PredictionItem.ketchup, searchViewStore: .storeSetUpForPreviewing),
        SearchResultItem(prediction: PredictionItem.publicPlace, searchViewStore: .storeSetUpForPreviewing)
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
