//
//  SearchSheet.swift
//  HudHud
//
//  Created by Patrick Kladek on 01.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import Foundation
import MapKit
import MapLibre
import MapLibreSwiftUI
import OSLog
import SwiftUI

// MARK: - SearchSheet

struct SearchSheet: View {

    // MARK: Properties

    var mapStore: MapStore
    @ObservedObject var searchStore: SearchViewStore
    @ObservedObject var trendingStore: TrendingStore
    @Bindable var sheetStore: SheetStore
    @ObservedObject var filterStore: FilterStore
    @Environment(\.dismiss) var dismiss
    @State var loginShown: Bool = false

    @State private var showAlert = false

    @FocusState private var searchIsFocused: Bool

    // MARK: Lifecycle

    init(mapStore: MapStore, searchStore: SearchViewStore, trendingStore: TrendingStore, sheetStore: SheetStore, filterStore: FilterStore) {
        self.mapStore = mapStore
        self.searchStore = searchStore
        self.trendingStore = trendingStore
        self.sheetStore = sheetStore
        self.filterStore = filterStore
        self.searchIsFocused = false
    }

    // MARK: Content

    var body: some View {
        VStack {
            HStack(spacing: 0) {
                HStack {
                    Image(systemSymbol: .magnifyingglass)
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 8)
                    TextField("Search", text: self.$searchStore.searchText)
                        .submitLabel(.search)
                        .focused(self.$searchIsFocused)
                        .padding(.vertical, 10)
                        .autocorrectionDisabled()
                        .overlay(
                            HStack {
                                Spacer()
                                if !self.searchStore.searchText.isEmpty {
                                    Button {
                                        self.searchStore.cancelSearch()
                                    } label: {
                                        Image(systemSymbol: .multiplyCircleFill)
                                            .foregroundColor(.gray)
                                            .frame(minWidth: 44, minHeight: 44)
                                    }
                                }
                            }
                        )
                        .onSubmit {
                            Task {
                                await self.searchStore.fetch(category: self.searchStore.searchText, enterSearch: true)
                            }
                        }
                        .padding(.horizontal, 10)

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
                Button {
                    if AuthProvider.shared.isLoggedIn() {
                        // Show alert if the user is already logged in
                        self.showAlert = true
                    } else {
                        // Proceed with login flow
                        // dismiss the search and show login view
                        self.loginShown = true
                    }
                } label: {
                    Image(systemSymbol: .person)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.gray)
                        .frame(width: 22, height: 22)
                        .padding(17)
                        .background {
                            Circle()
                                .foregroundColor(Color.Colors.General._03LightGrey)
                                .frame(width: 44, height: 44)
                        }
                }
            }
            .padding(.horizontal)
            .padding(.top)
            // Show the filter UI if the search view is displaying an item that was fetched from a category.
            if let firstItem = self.searchStore.searchResults.first,
               case .categoryItem = firstItem {
                MainFiltersView(searchStore: self.searchStore, filterStore: self.filterStore)
                    .padding(.horizontal)
                    .padding(.top)
            }
            if self.searchStore.loadingInstance.shouldShowLoadingCircle {
                VStack {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .cornerRadius(7.0)
                        .controlSize(.large)
                }
                .tint(Color.Colors.General._10GreenMain)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 2, trailing: 8))
                .padding()
            } else {
                List {
                    if !self.searchStore.searchText.isEmpty {
                        ForEach(self.searchStore.searchResults) { item in
                            switch item {
                            case let .categoryItem(item):
                                Button {
                                    self.sheetStore.show(.pointOfInterest(item))
                                } label: {
                                    SearchResultView(item: item) {
                                        self.sheetStore.show(.pointOfInterest(item))
                                    }
                                }
                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                .listRowSpacing(0)
                            case .predictionItem, .category, .resolvedItem:
                                Button {
                                    Task {
                                        self.searchIsFocused = false
                                        await self.searchStore.didSelect(item)
                                        if let resolvedItem = self.mapStore.selectedItem.value {
                                            self.storeRecent(item: resolvedItem)
                                        }
                                        switch self.searchStore.searchType {
                                        case let .returnPOILocation(completion):
                                            if let selectedItem = self.mapStore.selectedItem.value {
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
                                }
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 2, trailing: 8))
                            }
                        }
                        .listStyle(.plain)
                        if self.searchStore.loadingInstance.shouldShowNoResult {
                            let label = self.searchStore.searchError?.localizedDescription != nil ? "Search Error" : "No results"
                            ContentUnavailableView {
                                Label(label, systemSymbol: .magnifyingglass)
                            } description: {
                                Text("\(self.searchStore.searchError?.localizedDescription ?? "No results for \(self.searchStore.searchText) were found.")")
                            }
                            .padding(.vertical, 50)
                            .listRowSeparator(.hidden)
                        }
                    } else {
                        if self.searchStore.searchType != .favorites {
                            SearchSectionView(title: "Favorites") {
                                FavoriteCategoriesView(sheetStore: self.sheetStore)
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
                            RecentSearchResultsView(
                                searchStore: self.searchStore,
                                searchType: self.searchStore.searchType,
                                sheetStore: self.sheetStore
                            )
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 8))
                        .listRowSeparator(.hidden)
                    }
                }
                .scrollIndicators(.hidden)
                .listStyle(.plain)
            }
        }
        .onChange(of: self.searchStore.searchText) { _, _ in
            self.searchStore.loadingInstance.state = .initialLoading
            self.searchStore.startFetchingResultsTimer()
        }
        .fullScreenCover(isPresented: self.$loginShown) {
            UserLoginView(loginStore: LoginStore())
                .toolbarRole(.editor)
        }
        .alert(isPresented: self.$showAlert) {
            Alert(
                title: Text("Already Logged In"),
                message: Text("We are currently working on the UI and this feature is a work in progress."),
                primaryButton: .default(Text("Log Out"), action: {
                    self.logOut()
                }),
                secondaryButton: .default(Text("OK"))
            )
        }
        .onAppear {
            self.searchStore.applySearchResultsOnMapIfNeeded()
        }
    }

    // MARK: Functions

    func storeRecent(item: ResolvedItem) {
        withAnimation {
            self.searchStore.storeInRecent(item)
        }
    }

    // MARK: - Internal

    // Log out function
    private func logOut() {
        do {
            try AuthProvider.shared.delete()
            print("Logged out")
        } catch {
            print("Error logging out: \(error)")
        }
    }
}

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

extension [ResolvedItem]: @retroactive RawRepresentable {
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
    let trendingStroe = TrendingStore()
    SearchSheet(mapStore: .storeSetUpForPreviewing, searchStore: .storeSetUpForPreviewing, trendingStore: trendingStroe, sheetStore: .storeSetUpForPreviewing, filterStore: .storeSetUpForPreviewing)
}
