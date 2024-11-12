//
//  AddPOIToRouteProvider.swift
//  HudHud
//
//  Created by Naif Alrashed on 10/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import Combine
import SwiftUI

struct AddPOIToRouteProvider: SheetProvider {

    // MARK: Properties

    let sheetStore: SheetStore
    let favoritesStore: FavoritesStore
    let navigationEngine: NavigationEngine
    let sheetDetentPublisher: CurrentValueSubject<DetentData, Never>
    let onAddItem: (ResolvedItem) -> Void

    // MARK: Content

    var sheetView: some View {
        // Initialize fresh instances of MapStore and SearchViewStore
        let freshSearchViewStore: SearchViewStore = {
            let tempStore = SearchViewStore(mapStore: MapStore(userLocationStore: .storeSetUpForPreviewing),
                                            sheetStore: self.sheetStore,
                                            filterStore: .shared,
                                            mode: .live(provider: .hudhud),
                                            navigationEngine: self.navigationEngine,
                                            sheetDetentPublisher: self.sheetDetentPublisher)
            tempStore.searchType = .returnPOILocation(completion: self.onAddItem)
            return tempStore
        }()
        return SearchSheet(mapStore: freshSearchViewStore.mapStore,
                           searchStore: freshSearchViewStore,
                           trendingStore: TrendingStore(),
                           sheetStore: self.sheetStore,
                           filterStore: .shared,
                           favoritesStore: self.favoritesStore)
    }

    var mapOverlayView: some View {
        EmptyView()
    }
}
