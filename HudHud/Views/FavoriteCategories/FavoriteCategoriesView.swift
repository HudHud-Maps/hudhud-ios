//
//  FavoriteCategoriesView.swift
//  HudHud
//
//  Created by Alaa . on 27/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import SFSafeSymbols
import SwiftUI

struct FavoriteCategoriesView: View {
    let mapStore: MapStore
    let searchStore: SearchViewStore

    let plusButton = FavoriteCategoriesData(id: 4, title: "Add",
                                            sfSymbol: .plusCircleFill,
                                            tintColor: .green, item: nil, type: "Add")
    @AppStorage("favorites") var favorites = FavoritesResolvedItems(items: FavoriteCategoriesData.favoritesInit)

//    @State var ViewMoreShown: Bool = false

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(self.favorites.favoriteCategoriesData.prefix(4)) { favorite in
                    Button {
                        if let selectedItem = favorite.item {
                            let mapItems = [AnyDisplayableAsRow(selectedItem)]
                            self.mapStore.selectedItem = selectedItem
                            self.mapStore.displayableItems = mapItems
                        }
                    } label: {
                        Text(favorite.title)
                    }
                    .buttonStyle(FavoriteCategoriesButton(sfSymbol: favorite.sfSymbol, tintColor: favorite.tintColor))
                }
                Button {
                    print("\(self.plusButton.title) was pressed")
                } label: {
                    Text(self.plusButton.title)
                }.buttonStyle(FavoriteCategoriesButton(sfSymbol: self.plusButton.sfSymbol, tintColor: self.plusButton.tintColor))
            }
            Spacer()
        }
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
