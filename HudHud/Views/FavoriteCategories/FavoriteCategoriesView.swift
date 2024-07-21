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

    @AppStorage("favorites") var favorites = FavoritesResolvedItems(items: FavoritesItem.favoritesInit)

    @State var viewMoreShown: Bool = false

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(self.favorites.favoritesItems.prefix(4)) { favorite in
                    Button {
                        if let selectedItem = favorite.item {
                            self.mapStore.selectedItem = selectedItem
                            self.mapStore.displayableItems = [DisplayableRow.resolvedItem(selectedItem)]
                        }
                    } label: {
                        Text(favorite.type)
                    }
                    .buttonStyle(FavoriteCategoriesButton(sfSymbol: favorite.getSymbol(type: favorite.type), tintColor: favorite.tintColor))
                }
                Button {
                    self.viewMoreShown = true
                } label: {
                    Text("Add")
                }.buttonStyle(FavoriteCategoriesButton(sfSymbol: .plusCircleFill, tintColor: .green))
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
                    .hudhudFont(.title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Spacer()
                NavigationLink {
                    FavoritesViewMoreView(searchStore: .storeSetUpForPreviewing, mapStore: .storeSetUpForPreviewing)
                } label: {
                    HStack {
                        Text("View More")
                            .foregroundStyle(Color(UIColor.label))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        Image(systemSymbol: .chevronRight)
                            .font(.caption)
                            .foregroundStyle(Color(UIColor.label))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }
            }
            FavoriteCategoriesView(mapStore: .storeSetUpForPreviewing, searchStore: .storeSetUpForPreviewing)
        }
        .padding()
    }
}
