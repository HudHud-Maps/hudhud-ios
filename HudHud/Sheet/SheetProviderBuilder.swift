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
        default:
            EmptySheetProvider()
        }
    }
}

// swiftlint:enable function_parameter_count

//                switch sheetType {
//                case .debugView:
//                    return DebugMenuView(debugSettings: self.debugStore, sheetStore: self.sheetStore)
////                        .onDisappear(perform: {
////                            self.sheetStore.popToRoot()
////                        })
//                case let .navigationAddSearchView(onAddItem):
//                    // Initialize fresh instances of MapStore and SearchViewStore
//                    let freshMapStore = MapStore(userLocationStore: .storeSetUpForPreviewing)
//                    let freshSearchViewStore: SearchViewStore = {
//                        let freshRoutingStore = RoutingStore(mapStore: freshMapStore, routesPlanMapDrawer: RoutesPlanMapDrawer())
//                        let tempStore = SearchViewStore(
//                            mapStore: freshMapStore,
//                            sheetStore: SheetStore(emptySheetType: .search),
//                            routingStore: freshRoutingStore,
//                            filterStore: self.searchViewStore.filterStore,
//                            mode: self.searchViewStore.mode
//                        )
//                        tempStore.searchType = .returnPOILocation(completion: onAddItem)
//                        return tempStore
//                    }()
//                    return SearchSheet(
//                        mapStore: freshSearchViewStore.mapStore,
//                        searchStore: freshSearchViewStore,
//                        trendingStore: self.trendingStore,
//                        sheetStore: self.sheetStore,
//                        filterStore: self.searchViewStore.filterStore
//                    )
//                case .favorites:
//                    // Initialize fresh instances of MapStore and SearchViewStore
//                    let freshMapStore = MapStore(userLocationStore: .storeSetUpForPreviewing)
//                    let freshRoutingStore = RoutingStore(mapStore: freshMapStore, routesPlanMapDrawer: RoutesPlanMapDrawer())
//                    let freshSearchViewStore: SearchViewStore = {
//                        let tempStore = SearchViewStore(
//                            mapStore: freshMapStore,
//                            sheetStore: SheetStore(emptySheetType: .search),
//                            routingStore: freshRoutingStore,
//                            filterStore: self.searchViewStore.filterStore,
//                            mode: self.searchViewStore.mode
//                        )
//                        tempStore.searchType = .favorites
//                        return tempStore
//                    }()
//                    return SearchSheet(
//                        mapStore: freshSearchViewStore.mapStore,
//                        searchStore: freshSearchViewStore,
//                        trendingStore: self.trendingStore,
//                        sheetStore: SheetStore(emptySheetType: .search),
//                        filterStore: self.searchViewStore.filterStore
//                    )
//                case .navigationPreview:
//                    return NavigationSheetView(routingStore: self.searchViewStore.routingStore, sheetStore: self.sheetStore)
//                case let .pointOfInterest(item):
//                    return POIDetailSheet(
//                        pointOfInterestStore: PointOfInterestStore(
//                            pointOfInterest: item,
//                            mapStore: self.mapStore,
//                            sheetStore: self.sheetStore
//                        ), sheetStore: self.sheetStore,
//                        routingStore: self.searchViewStore.routingStore,
//                        didDenyLocationPermission: self.userLocationStore.permissionStatus.didDenyLocationPermission
//                    ) { routeIfAvailable in
//                        Logger.searchView.info("Start item \(item)")
//                        if self.debugStore.enableNewRoutePlanner {
//                            self.sheetStore.show(.routePlanner(RoutePlannerStore(
//                                sheetStore: self.sheetStore,
//                                userLocationStore: self.userLocationStore,
//                                mapStore: self.mapStore,
//                                routingStore: self.searchViewStore.routingStore,
//                                routesPlanMapDrawer: self.routesPlanMapDrawer,
//                                destination: item
//                            )))
//                            return
//                        }
//                        Task {
//                            do {
//                                try await self.searchViewStore.routingStore.showRoutes(
//                                    to: item,
//                                    with: routeIfAvailable
//                                )
//                                try await self.notificationManager.requestAuthorization()
//                                self.sheetStore.show(.navigationPreview)
//                            } catch {
//                                Logger.routing.error("Error navigating to \(item): \(error)")
//                            }
//                        }
//                    } onDismiss: {
//                        self.searchViewStore.mapStore
//                            .clearItems(clearResults: false)
//                        self.sheetStore.popSheet()
//                    }
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
