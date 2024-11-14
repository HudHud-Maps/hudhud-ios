//
//  EditFavoritesFormSheetProvider.swift
//  HudHud
//
//  Created by Naif Alrashed on 10/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import SwiftUI

struct EditFavoritesFormSheetProvider: SheetProvider {

    // MARK: Properties

    let favoritesStore: FavoritesStore
    let sheetStore: SheetStore
    let item: ResolvedItem
    let favoritesItem: FavoritesItem?

    // MARK: Content

    var sheetView: some View {
        EditFavoritesFormView(
            item: self.item,
            favoritesItem: self.favoritesItem,
            favoritesStore: self.favoritesStore,
            sheetStore: self.sheetStore
        )
    }

    var mapOverlayView: some View {
        EmptyView()
    }
}
