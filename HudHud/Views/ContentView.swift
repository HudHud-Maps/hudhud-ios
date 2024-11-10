//
//  ContentView.swift
//  HudHud
//
//  Created by Patrick Kladek on 29.01.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import BetterSafariView
import CoreLocation
import FerrostarCore
import FerrostarCoreFFI
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import NavigationTransitions
import OSLog
import SFSafeSymbols
import SimpleToast
import SwiftLocation
import SwiftUI
import TouchVisualizer

// MARK: - ContentView

@MainActor
struct ContentView: View {

    // MARK: Properties

    @StateObject var debugStore: DebugStore
    @State var safariURL: URL?

    @StateObject var favoritesStore = FavoritesStore()
    @StateObject var notificationManager = NotificationManager()

    // NOTE: As a workaround until Toursprung prvides us with an endpoint that services this file
    private let styleURL = URL(string: "https://static.maptoolkit.net/styles/hudhud/hudhud-default-v1.json?api_key=hudhud")! // swiftlint:disable:this force_unwrapping

    @State private var mapStore: MapStore

    @StateObject private var routingStore: RoutingStore

    @State private var streetViewStore: StreetViewStore
    @State private var sheetSize: CGSize = .zero
    private var routesPlanMapDrawer: RoutesPlanMapDrawer

    @StateObject private var notificationQueue = NotificationQueue()

    @ObservedObject private var userLocationStore: UserLocationStore
    @StateObject private var mapLayerStore = HudHudMapLayerStore()

    @State private var sheetStore: SheetStore

    // MARK: Lifecycle

    @MainActor
    init(userLocationStore: UserLocationStore) {
        let mapStore = MapStore(userLocationStore: userLocationStore)
        self.mapStore = mapStore

        let routesPlanMapDrawer = RoutesPlanMapDrawer()
        self.routesPlanMapDrawer = routesPlanMapDrawer

        let routingStore = RoutingStore(mapStore: mapStore, routesPlanMapDrawer: routesPlanMapDrawer)
        self._routingStore = StateObject(wrappedValue: routingStore)

        let streetViewStore = StreetViewStore(mapStore: mapStore)
        self.streetViewStore = streetViewStore

        let debugStore = DebugStore()
        self._debugStore = StateObject(wrappedValue: debugStore)

        let mapLayerStore = HudHudMapLayerStore()
        self._mapLayerStore = StateObject(wrappedValue: mapLayerStore)

        let favoritesStore = FavoritesStore()
        self._favoritesStore = StateObject(wrappedValue: favoritesStore)

        let sheetStore = SheetStore(
            emptySheetType: .search,
            makeSheetProvider: sheetProviderBuilder(
                userLocationStore: userLocationStore,
                debugStore: debugStore,
                mapStore: mapStore,
                routesPlanMapDrawer: routesPlanMapDrawer,
                hudhudMapLayerStore: mapLayerStore,
                favoritesStore: favoritesStore,
                routingStore: routingStore,
                streetViewStore: streetViewStore
            )
        )
        self.sheetStore = sheetStore

        self.userLocationStore = userLocationStore
    }

    // MARK: Content

    var body: some View {
        ZStack {
            MapViewContainer(
                mapStore: self.mapStore,
                debugStore: self.debugStore,
                userLocationStore: self.userLocationStore,
                routingStore: self.routingStore,
                sheetStore: self.sheetStore,
                streetViewStore: self.streetViewStore,
                routesPlanMapDrawer: self.routesPlanMapDrawer
            )
            .task {
                do {
                    let mapLayers = try await mapLayerStore.getMaplayers(baseURL: DebugStore().baseURL)
                    self.mapLayerStore.hudhudMapLayers = mapLayers
                    self.mapStore.updateCurrentMapStyle(mapLayers: mapLayers)
                } catch {
                    self.mapLayerStore.hudhudMapLayers = nil
                    Logger.searchView.error("\(error.localizedDescription)")
                }
            }
            .ignoresSafeArea()
            .edgesIgnoringSafeArea(.all)
            .overlay {
                MapOverlayView(mapOverlayStore: MapOverlayStore(sheetStore: self.sheetStore))
            }
            .safariView(item: self.$safariURL) { url in
                SafariView(url: url)
            }
            .onOpenURL { url in
                if let scheme = url.scheme, scheme == "https" || scheme == "http" {
                    self.safariURL = url
                    return .handled
                }
                return .systemAction
            }
            .environmentObject(self.notificationQueue)
            .simpleToast(item: self.$notificationQueue.currentNotification, options: .notification, onDismiss: {
                self.notificationQueue.removeFirst()
            }, content: {
                if let notification = self.notificationQueue.currentNotification {
                    NotificationBanner(notification: notification)
                        .padding(.horizontal, 8)
                }
            })
        }
    }
}

// MARK: - SimpleToastOptions

extension SimpleToastOptions {
    static let notification = SimpleToastOptions(alignment: .top, hideAfter: 5, modifierType: .slide)
}

private extension Binding where Value == Bool {

    static func && (_ lhs: Binding<Bool>, _ rhs: Binding<Bool>) -> Binding<Bool> {
        return Binding<Bool>(get: { lhs.wrappedValue && rhs.wrappedValue },
                             set: { _ in })
    }

    static prefix func ! (_ binding: Binding<Bool>) -> Binding<Bool> {
        return Binding<Bool>(
            get: { !binding.wrappedValue },
            set: { _ in }
        )
    }
}

// MARK: - Preview

#Preview {
    ContentView(userLocationStore: .storeSetUpForPreviewing)
}
