//
//  SheetProviderBuilder.swift
//  HudHud
//
//  Created by Naif Alrashed on 10/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import Foundation

// swiftlint:disable function_parameter_count
@MainActor
func sheetProviderBuilder(
    userLocationStore: UserLocationStore,
    debugStore: DebugStore,
    mapStore: MapStore,
    routesPlanMapDrawer: RoutesPlanMapDrawer,
    hudhudMapLayerStore: HudHudMapLayerStore,
    routingStore: RoutingStore,
    streetViewStore: StreetViewStore
) -> (SheetContext) -> any SheetProvider {
    { context in
        switch context.sheetType {
        case .search:
            SearchSheetProvider(
                sheetStore: context.sheetStore,
                searchViewStore: SearchViewStore(
                    mapStore: mapStore,
                    sheetStore: context.sheetStore,
                    routingStore: routingStore,
                    filterStore: .shared,
                    mode: .live(provider: .hudhud)
                ),
                streetViewStore: streetViewStore,
                trendingStore: TrendingStore()
            )
        case let .pointOfInterest(pointOfInterest):
            PointOfInterestSheetProvider(
                pointOfInterest: pointOfInterest,
                mapStore: mapStore,
                sheetStore: context.sheetStore,
                routingStore: routingStore,
                userLocationStore: userLocationStore,
                debugStore: debugStore,
                routePlannerStore: RoutePlannerStore(
                    sheetStore: context.sheetStore,
                    userLocationStore: userLocationStore,
                    mapStore: mapStore,
                    routingStore: routingStore,
                    routesPlanMapDrawer: routesPlanMapDrawer,
                    destination: pointOfInterest
                )
            )
        case .mapStyle:
            MapLayersSheetProvider(
                mapStore: mapStore,
                sheetStore: context.sheetStore,
                hudhudMapLayerStore: hudhudMapLayerStore
            )
        case .debugView:
            DebugMenuSheetProvider(
                debugStore: debugStore,
                sheetStore: context.sheetStore
            )
        case let .navigationAddSearchView(onAddItem):
            AddPOIToRouteProvider(
                sheetStore: context.sheetStore,
                onAddItem: onAddItem
            )
        case .favorites:
            FavoritesSheetProvider(sheetStore: context.sheetStore)
        case .navigationPreview:
            NavigationPreviewSheetProvider(
                sheetStore: context.sheetStore,
                routingStore: routingStore
            )
        default:
            EmptySheetProvider()
        }
    }
}

// swiftlint:enable function_parameter_count

//                switch sheetType {
//                case let .routePlanner(store):
//                    return RoutePlannerView(routePlannerStore: store)
//                case .favoritesViewMore:
//                    return FavoritesViewMoreView(
//                        searchStore: self.searchViewStore,
//                        sheetStore: self.sheetStore,
//                        favoritesStore: self.favoritesStore
//                    )
//                case let .editFavoritesForm(
//                    item: item,
//                    favoriteItem: favoriteItem
//                ):
//                    return EditFavoritesFormView(
//                        item: item,
//                        favoritesItem: favoriteItem,
//                        favoritesStore: self.favoritesStore,
//                        sheetStore: self.sheetStore
//                    )
//                case .search:
//                    return SearchSheet(
//                        mapStore: self.mapStore,
//                        searchStore: self.searchViewStore,
//                        trendingStore: self.trendingStore,
//                        sheetStore: self.sheetStore,
//                        filterStore: self.searchViewStore.filterStore
//                    )
//                }
// }
