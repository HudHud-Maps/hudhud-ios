//
//  RootSheetView.swift
//  HudHud
//
//  Created by patrick on 28.05.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import FerrostarCoreFFI
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
    @Bindable var mapViewStore: MapViewStore
    @ObservedObject var userLocationStore: UserLocationStore
    @Binding var sheetSize: CGSize

    @StateObject var notificationManager = NotificationManager()

    // MARK: Content

    var body: some View {
        NavigationStack(path: self.$mapViewStore.sheets) {
            SearchSheet(mapStore: self.mapStore,
                        searchStore: self.searchViewStore, trendingStore: self.trendingStore, mapViewStore: self.mapViewStore)
                .background(Color(.Colors.General._05WhiteBackground))
                .navigationDestination(for: SheetViewData.self) { value in
                    switch value.viewData {
                    case .mapStyle:
                        MapLayersView(mapStore: self.mapStore, mapViewStore: self.mapViewStore, hudhudMapLayerStore: self.mapLayerStore)
                            .navigationBarBackButtonHidden()
                            .presentationCornerRadius(21)
                    case .debugView:
                        DebugMenuView(debugSettings: self.debugStore)
                            .onDisappear(perform: {
                                self.mapViewStore.reset()
                            })
                            .navigationBarBackButtonHidden()
                    case .navigationAddSearchView:
                        // Initialize fresh instances of MapStore and SearchViewStore
                        let freshMapStore = MapStore(motionViewModel: .storeSetUpForPreviewing, userLocationStore: .storeSetUpForPreviewing)
                        let freshSearchViewStore: SearchViewStore = {
                            let freshRoutingStore = RoutingStore(mapStore: freshMapStore)
                            let tempStore = SearchViewStore(mapStore: freshMapStore, mapViewStore: MapViewStore(mapStore: freshMapStore, routingStore: freshRoutingStore), routingStore: freshRoutingStore, mode: self.searchViewStore.mode)
                            tempStore.searchType = .returnPOILocation(completion: { [routingStore = self.searchViewStore.routingStore] item in
                                routingStore.add(item)
                            })
                            return tempStore
                        }()
                        SearchSheet(mapStore: freshSearchViewStore.mapStore,
                                    searchStore: freshSearchViewStore, trendingStore: self.trendingStore, mapViewStore: self.mapViewStore).navigationBarBackButtonHidden()
                    case .favorites:
                        // Initialize fresh instances of MapStore and SearchViewStore
                        let freshMapStore = MapStore(motionViewModel: .storeSetUpForPreviewing, userLocationStore: .storeSetUpForPreviewing)
                        let freshRoutingStore = RoutingStore(mapStore: freshMapStore)
                        let freshSearchViewStore: SearchViewStore = { let tempStore = SearchViewStore(mapStore: freshMapStore, mapViewStore: MapViewStore(mapStore: freshMapStore, routingStore: freshRoutingStore), routingStore: freshRoutingStore, mode: self.searchViewStore.mode)
                            tempStore.searchType = .favorites
                            return tempStore
                        }()
                        SearchSheet(mapStore: freshSearchViewStore.mapStore,
                                    searchStore: freshSearchViewStore, trendingStore: self.trendingStore, mapViewStore: self.mapViewStore)
                    case .navigationPreview:
                        NavigationSheetView(routingStore: self.searchViewStore.routingStore, mapViewStore: self.mapViewStore)
                            .navigationBarBackButtonHidden()
                            .presentationCornerRadius(21)
                    case let .pointOfInterest(item):
                        POIDetailSheet(
                            item: item,
                            routingStore: self.searchViewStore.routingStore,
                            didDenyLocationPermission: self.userLocationStore.permissionStatus.didDenyLocationPermission
                        ) { routeIfAvailable in
                            Logger.searchView.info("Start item \(item)")
                            Task {
                                do {
                                    try await self.searchViewStore.routingStore.navigate(to: item, with: routeIfAvailable)
                                    try await self.notificationManager.requestAuthorization()
                                } catch {
                                    Logger.routing.error("Error navigating to \(item): \(error)")
                                }
                            }
                        } onDismiss: {
                            self.searchViewStore.mapStore.selectedItem = nil
                        }
                        .navigationBarBackButtonHidden()
                    }
                }
            /*
                .navigationDestination(isPresented:
                    Binding<Bool>(
                        get: { self.searchViewStore.routingStore.navigationProgress == .feedback },
                        set: { _ in }
                    )) {
                        RateNavigationView(mapViewStore: self.mapViewStore, selectedFace: { selectedFace in
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
        .navigationTransition(.fade(.cross))
        .frame(minWidth: 320)
        .presentationCornerRadius(21)
        .presentationDetents(
            self.mapViewStore.allowedDetents,
            selection: self.$mapViewStore.selectedDetent
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

#Preview {
    let searchViewStore: SearchViewStore = .storeSetUpForPreviewing
    return ContentView(searchStore: searchViewStore, mapViewStore: .storeSetUpForPreviewing)
}
