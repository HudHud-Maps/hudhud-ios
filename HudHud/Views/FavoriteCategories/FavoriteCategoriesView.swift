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

    // MARK: Properties

    var sheetStore: SheetStore
    let searchStore: SearchViewStore

    @ObservedObject var favoritesStore = FavoritesStore()

    // MARK: Content

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(self.favoritesStore.favoritesItems.prefix(4)) { favorite in
                    Button {
                        if let item = favorite.item {
                            self.searchStore.mapStore.clearListAndSelect(item)
                        }
                    } label: {
                        Text(favorite.type)
                            .hudhudFont(size: 12, fontWeight: .medium)
                    }
                    .buttonStyle(FavoriteCategoriesButton(sfSymbol: favorite.getSymbol(type: favorite.type), tintColor: favorite.tintColor.POI))
                }
                Button("Add") {
                    self.sheetStore.pushSheet(SheetViewData(viewData: .favoritesViewMore))
                }
                .hudhudFont(size: 12, fontWeight: .medium)
                .buttonStyle(FavoriteCategoriesButton(sfSymbol: .plusCircleFill, tintColor: Color.Colors.General._10GreenMain))
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
                    FavoritesViewMoreView(
                        searchStore: .storeSetUpForPreviewing,
                        sheetStore: .storeSetUpForPreviewing,
                        favoritesStore: .storeSetUpForPreviewing
                    )
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
            FavoriteCategoriesView(sheetStore: .storeSetUpForPreviewing, searchStore: .storeSetUpForPreviewing)
        }
        .padding()
    }
}
