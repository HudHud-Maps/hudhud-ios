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
    @ObservedObject var searchStore: SearchViewStore
    @ObservedObject var mapStore: MapStore
    @State var actionSheetShown: Bool = false
    @State var searchSheetShown: Bool = false
    @State var clickedFavorite: FavoritesItem = .favoriteForPreview
    @AppStorage("favorites") var favorites = FavoritesResolvedItems(items: FavoritesItem.favoritesInit)
    @Environment(\.dismiss) var dismiss

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
                ForEach(self.favorites.favoritesItems) { favorite in
                    if let favoriteItem = favorite.item {
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
                        EditFavoritesFormView(item: self.clickedFavorite.item ?? .starbucks, favoritesItem: self.clickedFavorite)
                    } label: {
                        Text("Edit")
                    }
                    Button(role: .destructive) {
                        let updatableTypes: Set<String> = ["Home", "School", "Work"]
                        if let index = self.favorites.favoritesItems.firstIndex(where: { $0 == clickedFavorite }), updatableTypes.contains(clickedFavorite.type) {
                            self.favorites.favoritesItems[index].item = nil
                        } else {
                            self.favorites.favoritesItems.removeAll(where: { $0.id == self.clickedFavorite.id })
                        }
                    } label: {
                        Text("Delete")
                    }
                }
            }

            Section("Suggestions") {
                RecentSearchResultsView(mapStore: self.mapStore, searchStore: self.searchStore, searchType: .favorites)
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
        .onChange(of: self.searchSheetShown) { _ in
            self.mapStore.path.append(SheetSubView.favorites)
        }
    }

    func searchSheetView() -> some View {
        let freshMapStore = MapStore(motionViewModel: .storeSetUpForPreviewing)
        let freshSearchViewStore = SearchViewStore(mapStore: freshMapStore, mode: self.searchStore.mode)
        freshSearchViewStore.searchType = .favorites
        return SearchSheet(mapStore: freshMapStore, searchStore: freshSearchViewStore, trendingStore: TrendingStore())
    }
}

#Preview {
    NavigationStack {
        FavoritesViewMoreView(searchStore: .storeSetUpForPreviewing, mapStore: .storeSetUpForPreviewing)
    }
}

#Preview("testing title") {
    @State var isLinkActive = true
    return NavigationStack {
        Text("root view")
            .navigationDestination(isPresented: $isLinkActive) {
                FavoritesViewMoreView(searchStore: .storeSetUpForPreviewing, mapStore: .storeSetUpForPreviewing)
            }
    }
}
