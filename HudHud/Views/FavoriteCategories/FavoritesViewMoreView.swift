//
//  FavoritesViewMoreView.swift
//  HudHud
//
//  Created by Alaa . on 30/05/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import MapKit
import MapLibreSwiftUI
import SwiftUI

// MARK: - FavoritesViewMoreView

struct FavoritesViewMoreView: View {

    // MARK: Properties

    @ObservedObject var searchStore: SearchViewStore
    @Bindable var sheetStore: SheetStore
    @State var actionSheetShown: Bool = false
    @State var searchSheetShown: Bool = false
    @State var clickedFavorite: FavoritesItem = .favoriteForPreview
    @ObservedObject var favoritesStore: FavoritesStore
    @StateObject var filterStore = FilterStore()

    // MARK: Content

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                VStack {
                    switch self.searchStore.searchType {
                    case .returnPOILocation, .favorites:
                        Button("Cancel") {
                            self.sheetStore.popSheet()
                        }
                        .foregroundColor(.gray)
                        .padding(.trailing)
                    case .selectPOI, .categories:
                        EmptyView()
                    }
                }
                .background(.thickMaterial)
                .cornerRadius(12)

                Section { // show my favorites
                    ForEach(self.favoritesStore.favoritesItems) { favorite in
                        if favorite.item != nil {
                            HStack {
                                FavoriteItemView(favorite: favorite)
                                Spacer()
                                Button {
                                    self.actionSheetShown = true
                                    self.clickedFavorite = favorite
                                } label: {
                                    Text("...")
                                        .foregroundStyle(Color(UIColor.label))
                                }
                            }
                        }
                    }
                    .confirmationDialog("action", isPresented: self.$actionSheetShown) {
                        Button("Edit") {
                            guard let item = self.clickedFavorite.item else { return }
                            self.sheetStore.show(.editFavoritesForm(
                                item: item,
                                favoriteItem: self.clickedFavorite
                            ))
                        }
                        Button("Delete", role: .destructive) {
                            self.favoritesStore.deleteFavorite(self.clickedFavorite)
                        }
                    }
                }

                Section("Suggestions") {
                    RecentSearchResultsView(
                        searchStore: self.searchStore,
                        searchType: .favorites,
                        sheetStore: self.sheetStore
                    )
                    Spacer()
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button {
                    self.sheetStore.popSheet()
                } label: {
                    Image(systemSymbol: .arrowBackward)
                },
                trailing: Button {
                    self.sheetStore.show(.favorites)
                } label: {
                    Image(systemSymbol: .plus)
                }
            )
        }
    }

    func searchSheetView() -> some View {
        let freshMapStore = MapStore(userLocationStore: .storeSetUpForPreviewing)
        let freshRoutingStore = RoutingStore(mapStore: freshMapStore)
        let freshSheetStore = SheetStore(emptySheetType: .search)
        let freshSearchViewStore = SearchViewStore(
            mapStore: freshMapStore,
            sheetStore: freshSheetStore,
            routingStore: freshRoutingStore,
            filterStore: FilterStore(),
            mode: self.searchStore.mode
        )
        freshSearchViewStore.searchType = .favorites
        return SearchSheet(
            mapStore: freshMapStore,
            searchStore: freshSearchViewStore,
            trendingStore: TrendingStore(),
            sheetStore: freshSheetStore,
            filterStore: FilterStore()
        )
    }
}

#Preview {
    NavigationStack {
        FavoritesViewMoreView(
            searchStore: .storeSetUpForPreviewing,
            sheetStore: .storeSetUpForPreviewing,
            favoritesStore: .storeSetUpForPreviewing
        )
    }
}

#Preview("testing title") {
    @Previewable @State var isLinkActive = true
    return NavigationStack {
        Text("root view")
            .navigationDestination(isPresented: $isLinkActive) {
                FavoritesViewMoreView(
                    searchStore: .storeSetUpForPreviewing,
                    sheetStore: .storeSetUpForPreviewing,
                    favoritesStore: .storeSetUpForPreviewing
                )
            }
    }
}
