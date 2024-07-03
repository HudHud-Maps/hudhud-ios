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
    @ObservedObject var mapStore: MapStore
    @ObservedObject var searchViewStore: SearchViewStore
    @ObservedObject var debugStore: DebugStore
    @ObservedObject var mapLayerStore: HudHudMapLayerStore
    @Binding var sheetSize: CGSize

    @StateObject var notificationManager = NotificationManager()

    var body: some View {
        NavigationStack(path: self.$mapStore.path) {
            SearchSheet(mapStore: self.mapStore,
                        searchStore: self.searchViewStore)
                .navigationDestination(for: SheetSubView.self) { value in
                    switch value {
                    case .mapStyle:
                        MapLayersView(hudhudMapLayerStore: self.mapLayerStore)
                            .navigationBarBackButtonHidden()
                            .presentationCornerRadius(21)

                    case .debugView:
                        DebugMenuView(debugSettings: self.debugStore)
                            .navigationBarBackButtonHidden()
                    case .navigationAddSearchView:
                        // Initialize fresh instances of MapStore and SearchViewStore
                        let freshMapStore = MapStore(motionViewModel: .storeSetUpForPreviewing)
                        let freshSearchViewStore: SearchViewStore = {
                            let tempStore = SearchViewStore(mapStore: freshMapStore, mode: self.searchViewStore.mode)
                            tempStore.searchType = .returnPOILocation(completion: { item in
                                self.searchViewStore.mapStore.waypoints?.append(item)
                            })
                            return tempStore
                        }()
                        SearchSheet(mapStore: freshSearchViewStore.mapStore,
                                    searchStore: freshSearchViewStore)
                    }
                }
                .navigationDestination(for: ResolvedItem.self) { item in
                    POIDetailSheet(item: item, onStart: { calculation in
                        Logger.searchView.info("Start item \(item)")
                        self.mapStore.routes = calculation
                        self.mapStore.displayableItems = [AnyDisplayableAsRow(item)]
                        if let location = calculation.waypoints.first {
                            self.mapStore.waypoints = [.myLocation(location), .waypoint(item)]
                        }
                        Task {
                            do {
                                try? await self.notificationManager.requestAuthorization()
                            }
                        }
                    }, onDismiss: {
                        self.searchViewStore.mapStore.selectedItem = nil
                        self.searchViewStore.mapStore.displayableItems = []
                    })
                    .navigationBarBackButtonHidden()
                }
                .navigationDestination(for: Toursprung.RouteCalculationResult.self) { _ in
                    NavigationSheetView(searchViewStore: self.searchViewStore, mapStore: self.mapStore, debugStore: self.debugStore)
                        .navigationBarBackButtonHidden()
                        .onDisappear(perform: {
                            if self.mapStore.path.contains(Toursprung.RouteCalculationResult.self) == false {
                                self.mapStore.waypoints = nil
                                self.mapStore.routes = nil
                            }
                        })
                        .presentationCornerRadius(21)
                }
                .navigationDestination(isPresented:
                    Binding<Bool>(
                        get: { self.mapStore.navigationProgress == .feedback },
                        set: { _ in }
                    )) {
                        RateNavigationView { selectedFace in
                            // selectedFace should be sent to backend along with detial of the route
                            self.mapStore.waypoints = nil
                            self.searchViewStore.mapStore.selectedItem = nil
                            self.searchViewStore.mapStore.displayableItems = []
                            self.mapStore.routes = nil
                            self.mapStore.navigationProgress = .none
                            Logger.routing.log("selected Face of rating: \(selectedFace)")
                        }
                        .navigationBarBackButtonHidden()
                        .presentationCornerRadius(21)
                }
        }
        .navigationTransition(.fade(.cross).animation(nil))
        .frame(minWidth: 320)
        .presentationCornerRadius(21)
        .presentationDetents(self.mapStore.allowedDetents, selection: self.$mapStore.selectedDetent)
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
    return ContentView(searchStore: searchViewStore)
}
