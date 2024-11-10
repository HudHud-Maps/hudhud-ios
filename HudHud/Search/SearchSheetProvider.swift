//
//  SearchSheetProvider.swift
//  HudHud
//
//  Created by Naif Alrashed on 09/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import SwiftUI

struct SearchSheetProvider: SheetProvider {

    // MARK: Properties

    let sheetStore: SheetStore
    let searchViewStore: SearchViewStore
    let streetViewStore: StreetViewStore
    let trendingStore: TrendingStore

    // MARK: Content

    var sheetView: some View {
        SearchSheet(
            mapStore: self.searchViewStore.mapStore,
            searchStore: self.searchViewStore,
            trendingStore: self.trendingStore,
            sheetStore: self.sheetStore,
            filterStore: self.searchViewStore.filterStore
        )
    }

    var mapOverlayView: some View {
        SearchMapOverlay(
            searchViewStore: self.searchViewStore,
            streetViewStore: self.streetViewStore,
            sheetStore: self.sheetStore,
            trendingStore: self.trendingStore,
            mapStore: self.searchViewStore.mapStore,
            userLocationStore: self.searchViewStore.mapStore.userLocationStore
        )
    }
}
