//
//  FavoritesSheetProvider.swift
//  HudHud
//
//  Created by Naif Alrashed on 10/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import SwiftUI

struct FavoritesSheetProvider: SheetProvider {

    // MARK: Properties

    let sheetStore: SheetStore

    // MARK: Content

    var sheetView: some View {
        // Initialize fresh instances of MapStore and SearchViewStore
        let freshMapStore = MapStore(userLocationStore: .storeSetUpForPreviewing)
        let freshRoutingStore = RoutingStore(mapStore: freshMapStore, routesPlanMapDrawer: RoutesPlanMapDrawer())
        let freshSearchViewStore: SearchViewStore = {
            let tempStore = SearchViewStore(
                mapStore: freshMapStore,
                sheetStore: self.sheetStore,
                routingStore: freshRoutingStore,
                filterStore: .shared,
                mode: .live(provider: .hudhud)
            )
            tempStore.searchType = .favorites
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
