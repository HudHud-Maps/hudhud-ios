//
//  RootSheetView.swift
//  HudHud
//
//  Created by patrick on 28.05.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
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
    @ObservedObject var mapViewStore: MapViewStore
    @Binding var sheetSize: CGSize
    @State var loginShown: Bool = false

    @StateObject var notificationManager = NotificationManager()

    // MARK: Content

    var body: some View {
        NavigationStack(path: self.$mapViewStore.path) {
            SearchSheet(mapStore: self.mapStore,
                        searchStore: self.searchViewStore, trendingStore: self.trendingStore, mapViewStore: self.mapViewStore, loginShown: self.$loginShown)
                .background(Color(.Colors.General._05WhiteBackground))
                .navigationDestination(for: SheetSubView.self) { value in
                    switch value {
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
                                    searchStore: freshSearchViewStore, trendingStore: self.trendingStore, mapViewStore: self.mapViewStore, loginShown: self.$loginShown).navigationBarBackButtonHidden()
                    case .favorites:
                        // Initialize fresh instances of MapStore and SearchViewStore
                        let freshMapStore = MapStore(motionViewModel: .storeSetUpForPreviewing, userLocationStore: .storeSetUpForPreviewing)
                        let freshRoutingStore = RoutingStore(mapStore: freshMapStore)
                        let freshSearchViewStore: SearchViewStore = { let tempStore = SearchViewStore(mapStore: freshMapStore, mapViewStore: MapViewStore(mapStore: freshMapStore, routingStore: freshRoutingStore), routingStore: freshRoutingStore, mode: self.searchViewStore.mode)
                            tempStore.searchType = .favorites
                            return tempStore
                        }()
                        SearchSheet(mapStore: freshSearchViewStore.mapStore,
                                    searchStore: freshSearchViewStore, trendingStore: self.trendingStore, mapViewStore: self.mapViewStore, loginShown: self.$loginShown)
                    }
                }
                .navigationDestination(for: ResolvedItem.self) { item in
                    POIDetailSheet(item: item, routingStore: self.searchViewStore.routingStore, onStart: { route in
                        Logger.searchView.info("Start item \(item)")
                        self.searchViewStore.routingStore.navigate(to: item, with: route)
                        Task {
                            do {
                                try? await self.notificationManager.requestAuthorization()
                            }
                        }
                    }, onDismiss: {
                        self.searchViewStore.mapStore.selectedItem = nil
                        self.searchViewStore.mapStore.displayableItems = []
                        if !self.mapViewStore.path.isEmpty {
                            self.mapViewStore.path.removeLast()
                        }
                    })
                    .navigationBarBackButtonHidden()
                }
                .navigationDestination(for: RoutingService.RouteCalculationResult.self) { _ in
                    NavigationSheetView(routingStore: self.searchViewStore.routingStore, mapViewStore: self.mapViewStore)
                        .navigationBarBackButtonHidden()
                        .onDisappear(perform: {
                            if self.mapViewStore.path.contains(RoutingService.RouteCalculationResult.self) == false {
                                self.searchViewStore.routingStore.endTrip()
                            }
                        })
                        .presentationCornerRadius(21)
                }
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
        }
        .fullScreenCover(isPresented: self.$loginShown) {
            UserLoginView(loginStore: LoginStore(), loginShown: self.$loginShown)
        }
        .navigationTransition(.fade(.cross).animation(nil))
        .frame(minWidth: 320)
        .presentationCornerRadius(21)
        .presentationDetents(self.mapViewStore.allowedDetents, selection: self.$mapViewStore.selectedDetent)
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
