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
func sheetProviderBuilder(userLocationStore: UserLocationStore,
                          debugStore: DebugStore,
                          mapStore: MapStore,
                          routesPlanMapDrawer: RoutesPlanMapDrawer,
                          hudhudMapLayerStore: HudHudMapLayerStore,
                          favoritesStore: FavoritesStore,
                          routingStore: RoutingStore,
                          navigationStore: NavigationStore,
                          navigationEngine: NavigationEngine,
                          streetViewStore: StreetViewStore) -> (SheetContext) -> any SheetProvider {
    { context in
        switch context.sheetType {
        case .search:
            return SearchSheetProvider(sheetStore: context.sheetStore,
                                       searchViewStore: SearchViewStore(mapStore: mapStore,
                                                                        sheetStore: context.sheetStore,
                                                                        filterStore: .shared,
                                                                        mode: .live(provider: .hudhud),
                                                                        navigationEngine: navigationEngine,
                                                                        sheetDetentPublisher: context.detentData),
                                       streetViewStore: streetViewStore,
                                       trendingStore: TrendingStore(),
                                       navigationStore: navigationStore,
                                       favoritesStore: favoritesStore)
        case let .pointOfInterest(pointOfInterest):
            return PointOfInterestSheetProvider(pointOfInterest: pointOfInterest,
                                                mapStore: mapStore,
                                                sheetStore: context.sheetStore,
                                                routingStore: routingStore,
                                                userLocationStore: userLocationStore,
                                                debugStore: debugStore,
                                                routePlannerStore: RoutePlannerStore(sheetStore: context.sheetStore,
                                                                                     userLocationStore: userLocationStore,
                                                                                     mapStore: mapStore,
                                                                                     navigationStore: navigationStore,
                                                                                     routesPlanMapDrawer: routesPlanMapDrawer,
                                                                                     destination: pointOfInterest),
                                                favoritesStore: favoritesStore)
        case .mapStyle:
            return MapLayersSheetProvider(mapStore: mapStore,
                                          sheetStore: context.sheetStore,
                                          hudhudMapLayerStore: hudhudMapLayerStore)
        case .debugView:
            return DebugMenuSheetProvider(debugStore: debugStore,
                                          sheetStore: context.sheetStore)
        case let .navigationAddSearchView(onAddItem):
            return AddPOIToRouteProvider(sheetStore: context.sheetStore,
                                         favoritesStore: favoritesStore,
                                         navigationEngine: navigationEngine,
                                         sheetDetentPublisher: context.detentData,
                                         onAddItem: onAddItem)
        case .favorites:
            return FavoritesSheetProvider(sheetStore: context.sheetStore,
                                          favoritesStore: favoritesStore,
                                          navigationEngine: navigationEngine,
                                          detentPublisher: context.detentData)
        case .navigationPreview:
            return NavigationPreviewSheetProvider(sheetStore: context.sheetStore,
                                                  routingStore: routingStore)
        case let .routePlanner(routePlannerStore):
            routePlannerStore.sheetDetentPublisher = context.detentData
            return RoutePlannerSheetProvider(routePlannerStore: routePlannerStore,
                                             sheetStore: context.sheetStore)
        case let .favoritesViewMore(searchViewStore):
            return FavoritesViewMoreSheetProvider(searchViewStore: searchViewStore,
                                                  favoritesStore: favoritesStore,
                                                  sheetStore: context.sheetStore)
        case let .editFavoritesForm(item, favoriteItem):
            return EditFavoritesFormSheetProvider(favoritesStore: favoritesStore,
                                                  sheetStore: context.sheetStore,
                                                  item: item,
                                                  favoritesItem: favoriteItem)
        case .loginNeeded:
            return LoginToSavePOISheetProvider(sheetStore: context.sheetStore)
        }
    }
}

// swiftlint:enable function_parameter_count
