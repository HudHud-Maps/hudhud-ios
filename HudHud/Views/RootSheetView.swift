//
//  RootSheetView.swift
//  HudHud
//
//  Created by patrick on 28.05.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import OSLog
import SwiftUI

struct RootSheetView: View {
    @ObservedObject var mapStore: MapStore
    @ObservedObject var searchViewStore: SearchViewStore
    @ObservedObject var debugStore: DebugStore
    @Binding var sheetSize: CGSize

    var body: some View {
        NavigationStack(path: self.$mapStore.path) {
            SearchSheet(mapStore: self.mapStore,
                        searchStore: self.searchViewStore)
                .navigationDestination(for: SheetSubView.self) { value in
                    switch value {
                    case .mapStyle:
                        VStack(alignment: .center, spacing: 25) {
                            Spacer()
                            HStack(alignment: .center) {
                                Spacer()
                                Text("Layers")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Button {
                                    self.mapStore.path.removeLast()
                                } label: {
                                    Image(systemSymbol: .xmark)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 30)
                            MainLayersView(mapLayerData: MapLayersData.getLayers())
                                .navigationBarBackButtonHidden()
                                .presentationCornerRadius(21)
                        }
                    case .debugView:
                        DebugMenuView(debugSettings: self.debugStore)
                            .navigationBarBackButtonHidden()
                    case .navigationAddSearchView:
                        // Initialize fresh instances of MapStore and SearchViewStore
                        let freshMapStore = MapStore(motionViewModel: .storeSetUpForPreviewing)
                        let freshSearchViewStore: SearchViewStore = { let tempStore = SearchViewStore(mapStore: freshMapStore, mode: self.searchViewStore.mode)
                            tempStore.searchType = .returnPOILocation(completion: { item in
                                self.searchViewStore.mapStore.waypoints?.append(item)

                            })
                            return tempStore
                        }()
                        SearchSheet(mapStore: freshSearchViewStore.mapStore,
                                    searchStore: freshSearchViewStore)
                    case .favorites:
                        // Initialize fresh instances of MapStore and SearchViewStore
                        let freshMapStore = MapStore(motionViewModel: .storeSetUpForPreviewing)
                        let freshSearchViewStore: SearchViewStore = { let tempStore = SearchViewStore(mapStore: freshMapStore, mode: self.searchViewStore.mode)
                            tempStore.searchType = .favorites
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
                        if let location = calculation.waypoints.first {
                            self.mapStore.waypoints = [.myLocation(location), .waypoint(item)]
                        }
                    }, onDismiss: {
                        self.mapStore.selectedItem = nil
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
            // withAnimation(.easeOut) {
            self.sheetSize = value
            // }
        }
    }
}

#Preview {
    let searchViewStore: SearchViewStore = .storeSetUpForPreviewing
    return ContentView(searchStore: searchViewStore)
}
