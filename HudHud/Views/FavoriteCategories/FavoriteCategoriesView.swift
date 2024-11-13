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

    @ObservedObject var favoritesStore: FavoritesStore

    // MARK: Content

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(FavoritesItem.favoritesInit) { favorite in
                    Button {
                        if let item = favorite.item {
                            self.sheetStore.show(.pointOfInterest(item))
                        }
                    } label: {
                        Text(favorite.type)
                            .hudhudFont(size: 12, fontWeight: .medium)
                    }
                    .buttonStyle(FavoriteCategoriesButton(sfSymbol: favorite.getSymbol(type: favorite.type), tintColor: favorite.tintColor.POI))
                }
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
                    FavoritesViewMoreView(sheetStore: .storeSetUpForPreviewing,
                                          favoritesStore: .storeSetUpForPreviewing)
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
            FavoriteCategoriesView(sheetStore: .storeSetUpForPreviewing, favoritesStore: FavoritesStore())
        }
        .padding()
    }
}
