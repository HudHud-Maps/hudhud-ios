//
//  FavoritesViewMoreView.swift
//  HudHud
//
//  Created by Alaa . on 26/05/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import POIService
import SwiftUI

// MARK: - FavoritesViewMoreView

struct FavoritesViewMoreView: View {
    @ObservedObject var searchStore: SearchViewStore
    @ObservedObject var mapStore: MapStore
    @State var actionSheetShown: Bool = false
    @State var searchShown: Bool = true
    @State var searchSheetShown: Bool = false
    @State var editFormShown: Bool = false
    @State var detailFormShown: Bool = false
    @State var clickedFav: FavoriteCategoriesData = .favoriteForPreview
    @State var clickedItem: ResolvedItem = .artwork
    @AppStorage("favorites") var favorites = FavoriteItems(items: FavoriteCategoriesData.favoritesInit)
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
                Button {} label: {
                    Image(systemSymbol: .plus)
                        .foregroundStyle(Color(UIColor.label))
                }
            }
            .padding(.vertical)
            VStack {
                HStack {
                    Image(systemSymbol: .magnifyingglass)
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 8)
                    TextField("Search", text: self.$searchStore.searchText)
                        //						.focused(self.$searchIsFocused)
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
                            .onChange(of: self.searchStore.searchText) { _ in
                                self.searchSheetShown = true
                            }
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
            .background(.thickMaterial)
            .cornerRadius(12)
            .padding(.vertical)
            Section {
                ForEach(self.favorites.favoriteCategoriesData) { favorite in
                    if favorite.item != nil {
                        HStack {
                            FavoriteItemView(favorite: favorite)
                            Spacer()
                            Button {
                                self.actionSheetShown = true
                                self.clickedFav = favorite
                            } label: {
                                Text("...")
                                    .foregroundStyle(Color(UIColor.label))
                            }
                            .confirmationDialog("action", isPresented: self.$actionSheetShown) {
                                Button {
                                    self.editFormShown = true
                                } label: {
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
            .fullScreenCover(isPresented: self.$editFormShown, content: {
                EditFavoriteForm(item: self.$clickedFav)
            })

            Section("Suggestions") {
                ForEach(self.searchStore.recentViewedItem) { item in
                    HStack {
                        if self.favorites.favoriteCategoriesData.contains(where: { $0.item == item }) { } else {
                            RecentSearchResultsView(item: item, mapStore: self.mapStore, searchStore: self.searchStore)
                            Spacer()
                            Button {
                                self.detailFormShown = true
                                self.clickedItem = item
                                self.clickedFav = FavoriteCategoriesData(id: .random(in: 100 ... 999), title: "\(self.clickedItem.title)", sfSymbol: self.clickedItem.symbol, tintColor: self.clickedItem.tintColor, type: self.clickedItem.category ?? "")
                            } label: {
                                Text("+")
                                    .foregroundStyle(Color(UIColor.label))
                            }
                        }
                    }
                }
                .fullScreenCover(isPresented: self.$detailFormShown, content: {
                    DetailFavoriteForm(item: self.$clickedItem, newFavorite: self.$clickedFav)
                })
            }
            Spacer()
        }
        .padding(.horizontal)
        .sheet(isPresented: self.$searchSheetShown) {
            let freshMapStore = MapStore(motionViewModel: .storeSetUpForPreviewing)
            let freshSearchViewStore = SearchViewStore(mapStore: freshMapStore, mode: self.searchStore.mode)
            SearchSheet(mapStore: freshMapStore,
                        searchStore: freshSearchViewStore)
                .onAppear {
                    freshSearchViewStore.searchType = .returnPOILocation { item in
                        DispatchQueue.main.async {
                            self.searchStore.mapStore.waypoints?.append(item)
                        }
                    }
                }
        }
    }
}

#Preview {
    FavoritesViewMoreView(searchStore: .storeSetUpForPreviewing, mapStore: .storeSetUpForPreviewing)
}

extension FavoriteCategoriesData {
    static var favoriteForPreview = FavoriteCategoriesData(id: 3, title: "School",
                                                           sfSymbol: .buildingColumnsFill,
                                                           tintColor: .gray, item: .pharmacy, description: " ", type: "School")
    static var favoritesInit = [
        FavoriteCategoriesData(id: 1, title: "Home",
                               sfSymbol: .houseFill,
                               tintColor: .gray, type: "Home"),
        FavoriteCategoriesData(id: 2, title: "Work",
                               sfSymbol: .bagFill,
                               tintColor: .gray, type: "Work"),
        FavoriteCategoriesData(id: 3, title: "School",
                               sfSymbol: .buildingColumnsFill,
                               tintColor: .gray, type: "School")
    ]
}
