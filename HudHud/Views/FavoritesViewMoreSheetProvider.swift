//
//  FavoritesViewMoreSheetProvider.swift
//  HudHud
//
//  Created by Naif Alrashed on 10/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct FavoritesViewMoreSheetProvider: SheetProvider {

    // MARK: Properties

    let searchViewStore: SearchViewStore
    let favoritesStore: FavoritesStore
    let sheetStore: SheetStore

    // MARK: Content

    var sheetView: some View {
        FavoritesViewMoreView(
            searchStore: self.searchViewStore,
            sheetStore: self.sheetStore,
            favoritesStore: self.favoritesStore
        )
    }

    var mapOverlayView: some View {
        EmptyView()
    }
}
