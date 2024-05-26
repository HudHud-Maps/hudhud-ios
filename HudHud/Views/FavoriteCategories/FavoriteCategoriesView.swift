//
//  FavoriteCategoriesView.swift
//  HudHud
//
//  Created by Alaa . on 27/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import POIService
import SFSafeSymbols
import SwiftUI

struct FavoriteCategoriesView: View {
    let mapStore: MapStore
    let searchStore: SearchViewStore
    let plusButton = FavoriteCategoriesData(id: 4, title: "Add",
                                            sfSymbol: .plusCircleFill,
                                            tintColor: .green, item: nil, type: "add")
    @AppStorage("favorites") var favorites = FavoriteItems(items: FavoriteCategoriesData.favoritesInit)
    @State var ViewMoreShown: Bool = false

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(self.favorites.favoriteCategoriesData.prefix(4)) { favorite in
                    Button {
                        if let selectedItem = favorite.item {
                            let mapItems = [AnyDisplayableAsRow(selectedItem)]
                            self.searchStore.selectedDetent = .medium
                            self.mapStore.selectedItem = selectedItem
                            self.mapStore.displayableItems = mapItems
                        } else {
                            self.ViewMoreShown = true
                        }
                    } label: {
                        Text(favorite.type)
                    }
                    .buttonStyle(FavoriteCategoriesButton(sfSymbol: favorite.sfSymbol, tintColor: favorite.tintColor))
                }
                Button {
                    self.ViewMoreShown = true
                } label: {
                    Text(self.plusButton.title)
                }.buttonStyle(FavoriteCategoriesButton(sfSymbol: self.plusButton.sfSymbol, tintColor: self.plusButton.tintColor))
            }
            Spacer()
        }
        .backport.scrollClipDisabled()
        //		.onAppear {
        ////			favorites.favoriteCategoriesData.append(contentsOf: favoriteCategoriesData)
        //			print("faav", favorites.favoriteCategoriesData.count)
        //		}
        .fullScreenCover(isPresented: self.$ViewMoreShown, content: {
            FavoritesViewMoreView(searchStore: self.searchStore, mapStore: self.mapStore)
        })
    }
}

#Preview {
    VStack(alignment: .leading) {
        HStack {
            Text("Favorites")
                .font(.system(.title))
                .bold()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Spacer()
            Text("View More >")
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        FavoriteCategoriesView(mapStore: .storeSetUpForPreviewing, searchStore: .storeSetUpForPreviewing)
    }
    .padding()
}
