//
//  AddPOIToRouteProvider.swift
//  HudHud
//
//  Created by Naif Alrashed on 10/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import SwiftUI

struct AddPOIToRouteProvider: SheetProvider {

    // MARK: Properties

    let sheetStore: SheetStore
    let onAddItem: (ResolvedItem) -> Void

    // MARK: Content

    var sheetView: some View {
        // Initialize fresh instances of MapStore and SearchViewStore
        let freshSearchViewStore: SearchViewStore = {
            let tempStore = SearchViewStore(
                mapStore: MapStore(userLocationStore: .storeSetUpForPreviewing),
                sheetStore: self.sheetStore,
                filterStore: .shared,
                mode: .live(provider: .hudhud)
            )
            tempStore.searchType = .returnPOILocation(completion: self.onAddItem)
            return tempStore
        }()
        return SearchSheet(
            mapStore: freshSearchViewStore.mapStore,
            searchStore: freshSearchViewStore,
            trendingStore: TrendingStore(),
            sheetStore: self.sheetStore,
            filterStore: .shared
        )
    }

    var mapOverlayView: some View {
        EmptyView()
    }
}
