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
    @ObservedObject var mapViewStore: MapViewStore
    @State var actionSheetShown: Bool = false
    @State var searchSheetShown: Bool = false
    @State var clickedFavorite: FavoritesItem = .favoriteForPreview
    @Environment(\.dismiss) var dismiss
    @ObservedObject var favoritesStore = FavoritesStore()
    @StateObject var filterStore = FilterStore()

    // MARK: Content

    var body: some View {
        VStack(alignment: .leading) {
            VStack {
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
                    NavigationLink {
                        EditFavoritesFormView(item: self.clickedFavorite.item ?? .starbucks, favoritesItem: self.clickedFavorite, favoritesStore: self.favoritesStore)
                    } label: {
                        Text("Edit")
                    }
                    Button(role: .destructive) {
                        self.favoritesStore.deleteFavorite(self.clickedFavorite)
                    } label: {
                        Text("Delete")
                    }
                }
            }

            Section("Suggestions") {
                RecentSearchResultsView(searchStore: self.searchStore, searchType: .favorites)
                Spacer()
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top)
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            trailing: Button {
                self.searchSheetShown = true
            } label: {
                Image(systemSymbol: .plus)
            }
        )

        .sheet(isPresented: self.$searchSheetShown) {
            self.searchSheetView()
        }
        .onChange(of: self.searchSheetShown) {
            self.mapViewStore.path.append(SheetSubView.favorites)
        }
    }

    func searchSheetView() -> some View {
        let freshMapStore = MapStore(userLocationStore: .storeSetUpForPreviewing)
        let freshRoutingStore = RoutingStore(mapStore: freshMapStore)
        let freshSearchViewStore = SearchViewStore(mapStore: freshMapStore, mapViewStore: MapViewStore(mapStore: freshMapStore, routingStore: freshRoutingStore), routingStore: freshRoutingStore, filterStore: filterStore, mode: self.searchStore.mode)
        freshSearchViewStore.searchType = .favorites
        return SearchSheet(mapStore: freshMapStore, searchStore: freshSearchViewStore, trendingStore: TrendingStore(), mapViewStore: self.mapViewStore, filterStore: self.filterStore)
    }
}

#Preview {
    NavigationStack {
        FavoritesViewMoreView(searchStore: .storeSetUpForPreviewing, mapViewStore: .storeSetUpForPreviewing)
    }
}

#Preview("testing title") {
    @Previewable @State var isLinkActive = true
    return NavigationStack {
        Text("root view")
            .navigationDestination(isPresented: $isLinkActive) {
                FavoritesViewMoreView(searchStore: .storeSetUpForPreviewing, mapViewStore: .storeSetUpForPreviewing)
            }
    }
}
