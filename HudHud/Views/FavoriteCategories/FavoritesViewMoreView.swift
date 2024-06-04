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
    @State var camera: MapViewCamera = .center(.riyadh, zoom: 16)
    @State var clickedFavorite: FavoriteCategoriesData = .favoriteForPreview
    @State var clickedItem: ResolvedItem = .artwork
    @AppStorage("favorites") var favorites = FavoritesResolvedItems(items: FavoriteCategoriesData.favoritesInit)
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button {
                    self.dismiss()
                } label: {
                    Image(systemSymbol: .chevronLeft)
                        .foregroundStyle(Color(UIColor.label))
                }
                Spacer()
                Text("Favorites")
                Spacer()
                Button {
                    self.searchSheetShown = true
                } label: {
                    Image(systemSymbol: .plus)
                        .foregroundStyle(Color(UIColor.label))
                }
            }
            .padding(.vertical)
            VStack {
                switch self.searchStore.searchType {
                case .returnPOILocation:
                    Button("Cancel", action: {
                        self.dismiss()
                    })
                    .foregroundColor(.gray)
                    .padding(.trailing)
                case .selectPOI:
                    EmptyView()
                case .favorites:
                    Button("Cancel", action: {
                        self.dismiss()
                    })
                    .foregroundColor(.gray)
                    .padding(.trailing)
                }
            }
            .background(.thickMaterial)
            .cornerRadius(12)

            Section { // show my favorites
                ForEach(self.favorites.favoriteCategoriesData) { favorite in
                    if favorite.item != nil {
                        HStack {
                            FavoriteItemView(favorite: favorite)
                            Spacer()
                            Button {
                                self.actionSheetShown = true
                                self.clickedFavorite = favorite
                                self.clickedItem = favorite.item!
                                self.camera = MapViewCamera.center(favorite.item!.coordinate, zoom: 14)
                            } label: {
                                Text("...")
                                    .foregroundStyle(Color(UIColor.label))
                            }
                            .confirmationDialog("action", isPresented: self.$actionSheetShown) {
                                Button {} label: {
                                    Text("Edit")
                                }
                                Button(role: .destructive) {} label: {
                                    Text("Delete")
                                }
                            }
                        }
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
        .sheet(isPresented: self.$searchSheetShown) {
            self.SearchSheetView()
        }
        .onChange(of: self.searchSheetShown) { _ in
            self.mapStore.path.append(SheetSubView.favorites)
        }
        .onAppear {
            print(self.favorites, "favorites")
        }
    }

    // MARK: - Internal

    func SearchSheetView() -> some View {
        let freshMapStore = MapStore(motionViewModel: .storeSetUpForPreviewing)
        let freshSearchViewStore = SearchViewStore(mapStore: freshMapStore, mode: self.searchStore.mode)
        freshSearchViewStore.searchType = .favorites
        return SearchSheet(mapStore: freshMapStore, searchStore: freshSearchViewStore)
    }
}

#Preview {
    FavoritesViewMoreView(searchStore: .storeSetUpForPreviewing, mapStore: .storeSetUpForPreviewing)
}
