//
//  RootSheetView.swift
//  HudHud
//
//  Created by patrick on 28.05.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import FerrostarCoreFFI
import Foundation
import MapLibreSwiftUI
import OSLog
import SwiftUI

struct RootSheetView: View {

    // MARK: Properties

    @ObservedObject var mapStore: MapStore
    @ObservedObject var searchViewStore: SearchViewStore
    @ObservedObject var debugStore: DebugStore
    @ObservedObject var trendingStore: TrendingStore
    @ObservedObject var mapLayerStore: HudHudMapLayerStore
    @ObservedObject var sheetStore: SheetStore
    @ObservedObject var userLocationStore: UserLocationStore
    @Binding var sheetSize: CGSize
    @StateObject var favoritesStore = FavoritesStore()

    @StateObject var notificationManager = NotificationManager()

    @ObservedObject var navigationVisualization: NavigationVisualization

    // MARK: Content

    var body: some View {
        NavigationStack(path: self.$sheetStore.sheets) {
            SearchSheet(mapStore: self.mapStore,
                        searchStore: self.searchViewStore, trendingStore: self.trendingStore, sheetStore: self.sheetStore, filterStore: self.searchViewStore.filterStore)
                .background(Color(.Colors.General._05WhiteBackground))
                .toolbar(.hidden)
                .navigationDestination(for: SheetViewData.self) { value in
                    switch value.viewData {
                    case .mapStyle:
                        MapLayersView(mapStore: self.mapStore, sheetStore: self.sheetStore, hudhudMapLayerStore: self.mapLayerStore)
                            .navigationBarBackButtonHidden()
                            .presentationCornerRadius(21)
                    case .debugView:
                        DebugMenuView(debugSettings: self.debugStore)
                            .onDisappear(perform: {
                                self.sheetStore.reset()
                            })
                            .navigationBarBackButtonHidden()
                    case .navigationAddSearchView:
                        // Initialize fresh instances of MapStore and SearchViewStore
                        let freshMapStore = MapStore(motionViewModel: .storeSetUpForPreviewing, userLocationStore: .storeSetUpForPreviewing)
                        let freshSearchViewStore: SearchViewStore = {
                            self.navigationVisualization.clear()

                            let tempStore = SearchViewStore(
                                mapStore: freshMapStore,
                                sheetStore: SheetStore(),
                                navigationVisualization: navigationVisualization,
                                filterStore: self.searchViewStore.filterStore,
                                mode: self.searchViewStore.mode
                            )
                            tempStore.searchType = .returnPOILocation(completion: { item in
                                self.navigationVisualization.add(item)
                            })
                            return tempStore
                        }()
                        SearchSheet(
                            mapStore: freshSearchViewStore.mapStore,
                            searchStore: freshSearchViewStore,
                            trendingStore: self.trendingStore,
                            sheetStore: self.sheetStore,
                            filterStore: self.searchViewStore.filterStore
                        )
                        .navigationBarBackButtonHidden()
                    case .favorites:
                        // Initialize fresh instances of MapStore and SearchViewStore
                        let freshMapStore = MapStore(motionViewModel: .storeSetUpForPreviewing, userLocationStore: .storeSetUpForPreviewing)
//                        let freshRoutingStore = RoutingStore(mapStore: freshMapStore)
//                        _ = navigationVisualization.clear()
                        let freshSearchViewStore: SearchViewStore = {
                            let tempStore = SearchViewStore(
                                mapStore: freshMapStore,
                                sheetStore: SheetStore(),
                                navigationVisualization: navigationVisualization,
                                filterStore: self.searchViewStore.filterStore,
                                mode: self.searchViewStore.mode
                            )
                            tempStore.searchType = .favorites
                            return tempStore
                        }()
                        SearchSheet(
                            mapStore: freshSearchViewStore.mapStore,
                            searchStore: freshSearchViewStore,
                            trendingStore: self.trendingStore,
                            sheetStore: SheetStore(),
                            filterStore: self.searchViewStore.filterStore
                        )
                    case .navigationPreview:
                        NavigationSheetView(
                            sheetStore: self.sheetStore,
                            navigationVisualization: self.navigationVisualization
                        )
                        .navigationBarBackButtonHidden()
                        .presentationCornerRadius(21)
                    case let .pointOfInterest(item):
                        POIDetailSheet(
                            mapStore: self.mapStore,
                            item: item,
                            navigationVisualization: self.navigationVisualization,
                            didDenyLocationPermission: self.userLocationStore.permissionStatus.didDenyLocationPermission
                        ) { _ in
                            Logger.searchView.info("Start item \(item)")
                            Task {
                                guard let userLocation = await self.mapStore.userLocationStore.location(allowCached: false) else {
                                    return
                                }
                                self.mapStore.displayableItems = [DisplayableRow.resolvedItem(item)]

                                self.navigationVisualization.displayRoute(from: userLocation.coordinate, to: item.coordinate)

                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    if let location = navigationVisualization.routes.first?.waypoints.first {
                                        self.navigationVisualization.waypoints = [.myLocation(location), .waypoint(item)]
                                    }
                                }

                                //            self.waypoints = [.myLocation(location), .waypoint(item)]
                                //        }

//                                fatalError()
//                                do {
//                                    try await self.navigationVisualization.navigate(to: item, with: routeIfAvailable)
//                                    try await self.notificationManager.requestAuthorization()
//                                } catch {
//                                    Logger.routing.error("Error navigating to \(item): \(error)")
//                                }
                            }
                        }
                        preplanRoutes: { item in
                            Task {
                                do {
                                    guard let userLocation = await self.mapStore.userLocationStore.location(allowCached: false) else {
                                        return
                                    }

                                    try await self.navigationVisualization.preplanRoutes(
                                        from: userLocation.coordinate,
                                        to: item.coordinate
                                    )

                                } catch let error as URLError {
                                    if error.code == .cancelled {
                                        // ignore cancelled errors
                                        return
                                    }

                                    let notification = Notification(error: error)
//                                    self.notificationQueue.add(notification: notification)
                                } catch {
                                    // we do not show an error in all other cases
                                }
                            }
                        }
                        onDismiss: {
                            self.searchViewStore.mapStore
                                .clearItems(clearResults: false)
                        }
                        .navigationBarBackButtonHidden()
                    case .favoritesViewMore:
                        FavoritesViewMoreView(
                            searchStore: self.searchViewStore,
                            sheetStore: self.sheetStore,
                            favoritesStore: self.favoritesStore,
                            navigationVisualization: self.navigationVisualization
                        )
                    case let .editFavoritesForm(
                        item: item,
                        favoriteItem: favoriteItem
                    ):
                        EditFavoritesFormView(
                            item: item,
                            favoritesItem: favoriteItem,
                            favoritesStore: self.favoritesStore
                        )
                    }
                }
            /*
                .navigationDestination(isPresented:
                    Binding<Bool>(
                        get: { self.searchViewStore.routingStore.navigationProgress == .feedback },
                        set: { _ in }
                    )) {
                        RateNavigationView(sheetStore: self.sheetStore, selectedFace: { selectedFace in
                            // selectedFace should be sent to backend along with detial of the route
                            self.searchViewStore.endTrip()
                            Logger.routing.log("selected Face of rating: \(selectedFace)")
                        }, onDismiss: {
                            self.searchViewStore.endTrip()
                            Logger.routing.log("Dismiss Rating")
                        })
                        .navigationBarBackButtonHidden()
                        .presentationCornerRadius(21)
                }
             */
        }
        .navigationTransition(self.sheetStore.transition)
        .frame(minWidth: 320)
        .presentationCornerRadius(21)
        .presentationDetents(
            self.sheetStore.allowedDetents,
            selection: self.$sheetStore.selectedDetent
        )
        .presentationBackgroundInteraction(.enabled)
        .interactiveDismissDisabled()
        .ignoresSafeArea()
        .presentationCompactAdaptation(.sheet)
        .overlay {
            GeometryReader { geometry in
                Color.clear.preference(key: SizePreferenceKey.self, value: geometry.size)
            }
        }
        .onPreferenceChange(SizePreferenceKey.self) { value in
            self.sheetSize = value
        }
    }
}

// #Preview {
//    ContentView(
//        store: .init(
//            mapStore: .storeSetUpForPreviewing,
//            sheetStore: .storeSetUpForPreviewing,
//            mapViewStore: .storeSetUpForPreviewing,
//            searchViewStore: .storeSetUpForPreviewing,
//            userLocationStore: .storeSetUpForPreviewing,
//            navigationEngine: .init(),
//            mapContainerViewStore: MapViewContainerStore(
//                navigationVisualization: .init(
//                    navigationEngine: .init(),
//                    routePlanner: RoutePlanner(routingService: GraphHopperRouteProvider())
//                )
//            )
//        )
//    )
// }
