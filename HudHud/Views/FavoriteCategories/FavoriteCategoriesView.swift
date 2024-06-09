//
//  FavoriteCategoriesView.swift
//  HudHud
//
//  Created by Alaa . on 27/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import CoreLocation
import MapLibreSwiftUI
import SFSafeSymbols
import SwiftUI

struct FavoriteCategoriesView: View {
    let mapStore: MapStore
    let searchStore: SearchViewStore

    let plusButton = FavoritesItem(id: 4, title: "Add",
                                   sfSymbol: .plusCircleFill,
                                   tintColor: .green, item: nil, type: "Add")
    @AppStorage("favorites") var favorites = FavoritesResolvedItems(items: FavoritesItem.favoritesInit)

    @State var ViewMoreShown: Bool = false

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(self.favorites.favoritesItems.prefix(4)) { favorite in
                    Button {
                        if let selectedItem = favorite.item {
                            let mapItems = [AnyDisplayableAsRow(selectedItem)]
                            self.mapStore.selectedItem = selectedItem
                            self.mapStore.displayableItems = mapItems
                        }
                    } label: {
                        Text(favorite.type)
                    }
                    .buttonStyle(FavoriteCategoriesButton(sfSymbol: favorite.sfSymbol, tintColor: favorite.tintColor))
                }
                Button {
                    print("\(self.plusButton.title) was pressed")
                    self.ViewMoreShown = true
                } label: {
                    Text(self.plusButton.title)
                }.buttonStyle(FavoriteCategoriesButton(sfSymbol: self.plusButton.sfSymbol, tintColor: self.plusButton.tintColor))
            }
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        VStack(alignment: .leading) {
            HStack {
                Text("Favorites")
                    .font(.system(.title))
                    .bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Spacer()
                NavigationLink {
                    FavoritesViewMoreView(searchStore: .storeSetUpForPreviewing, mapStore: .storeSetUpForPreviewing)
                } label: {
                    Text("View More >")
                        .foregroundStyle(Color(UIColor.label))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            FavoriteCategoriesView(mapStore: .storeSetUpForPreviewing, searchStore: .storeSetUpForPreviewing)
        }
        .padding()
    }
}
