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
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import NavigationTransitions
import OSLog
import SFSafeSymbols
import SimpleToast
import SwiftUI
import TouchVisualizer

typealias TrendingPOI = ResolvedItem

// MARK: - ContentViewStore

@MainActor
final class ContentViewStore: ObservableObject {

    // MARK: Properties

    @Published var isSheetShown = true
    @Published var selectedDetent: PresentationDetent = .medium
    @Published var safariURL: URL?
    @Published var streetViewScene: StreetViewScene?
    @Published var fullScreenStreetView = false
    @Published var currentNotification: Notification?
    @Published var sheetSize: CGSize = .zero
    @Published var mapLayers: [HudHudMapLayer]?
    @Published var trendingPOIs: [TrendingPOI]?

    @ObservedObjectChild var sheetStore: SheetStore

    @ObservedObjectChild var mapStore: MapStore

    @ObservedObjectChild var searchViewStore: SearchViewStore

    @ObservedObjectChild var userLocationStore: UserLocationStore

    @ObservedObjectChild var debugStore: DebugStore

    @ObservedObjectChild var trendingStore: TrendingStore

    @ObservedObjectChild var mapLayerStore: HudHudMapLayerStore

    @ObservedObjectChild var mapViewStore: MapViewStore

    @ObservedObjectChild var navigationVisualization: NavigationVisualization

    @ObservedObjectChild var mapContainerViewStore: MapViewContainerStore

    @ObservedObjectChild var notificationQueue: NotificationQueue

    // MARK: Computed Properties

    var shouldHideContent: Bool {
        self.navigationVisualization.isNavigating || self.mapStore.streetViewScene != nil
    }

    var mapButtonData: [MapButtonData] {
        [
            MapButtonData(sfSymbol: .icon(.map)) {
                self.sheetStore.pushSheet(SheetViewData(viewData: .mapStyle))
            },
            MapButtonData(sfSymbol: MapButtonData.buttonIcon(for: self.searchViewStore.mode)) {
                switch self.searchViewStore.mode {
                case let .live(provider):
                    self.searchViewStore.mode = .live(provider: provider.next())
                    Logger.searchView.info("Map Mode live")
                case .preview:
                    self.searchViewStore.mode = .live(provider: .hudhud)
                    Logger.searchView.info("Map Mode toursprung")
                }
            },
            MapButtonData(sfSymbol: self.mapStore.getCameraPitch() > 0 ? .icon(.diamond) : .icon(.cube)) {
                if self.mapStore.getCameraPitch() > 0 {
                    self.mapStore.camera.setPitch(0)
                } else {
                    self.mapStore.camera.setZoom(17)
                    self.mapStore.camera.setPitch(60)
                }
            },
            MapButtonData(sfSymbol: .icon(.terminal)) {
                self.sheetStore.pushSheet(SheetViewData(viewData: .debugView))
            }
        ]
    }

    // MARK: Lifecycle

    init(
        mapStore: MapStore,
        sheetStore: SheetStore,
        mapViewStore: MapViewStore,
        searchViewStore: SearchViewStore,
        userLocationStore: UserLocationStore,
        navigationVisualization: NavigationVisualization,
        mapContainerViewStore: MapViewContainerStore
    ) {
        self.mapStore = mapStore
        self.searchViewStore = searchViewStore
        self.userLocationStore = userLocationStore
        self.debugStore = DebugStore()
        self.notificationQueue = NotificationQueue()
        self.trendingStore = TrendingStore()
        self.mapLayerStore = HudHudMapLayerStore()
        self.mapViewStore = mapViewStore
        self.navigationVisualization = navigationVisualization
        self.mapContainerViewStore = mapContainerViewStore
        self.sheetStore = sheetStore
    }

    // MARK: Functions

    func toggleMapMode() {
        switch self.searchViewStore.mode {
        case let .live(provider):
            self.searchViewStore.mode = .live(provider: provider.next())
        case .preview:
            self.searchViewStore.mode = .live(provider: .hudhud)
        }
    }

    func toggleCameraPitch() {
        if self.mapStore.getCameraPitch() > 0 {
            self.mapStore.camera.setPitch(0)
        } else {
            self.mapStore.camera.setZoom(17)
            self.mapStore.camera.setPitch(60)
        }
    }

    func showStreetView(_ item: StreetViewScene) {
        self.mapStore.streetViewScene = item
        AppQueue.delay(0.2) {
            self.mapStore.zoomToStreetViewLocation()
        }
    }

    @MainActor
    func updateMapLayers() async {
        do {
            let mapLayers = try await mapLayerStore.getMaplayers(baseURL: self.debugStore.baseURL)
            self.mapLayers = mapLayers
            self.mapStore.updateCurrentMapStyle(mapLayers: mapLayers)
        } catch {
            self.mapLayers = nil
            Logger.searchView.error("\(error.localizedDescription)")
        }
    }

    @MainActor
    func reloadPOITrending() async {
        do {
            let currentUserLocation = await userLocationStore.location(allowCached: true)?.coordinate
            let trendingPOI = try await trendingStore.getTrendingPOIs(page: 1, limit: 100, coordinates: currentUserLocation, baseURL: self.debugStore.baseURL)
            self.trendingPOIs = trendingPOI
        } catch {
            self.trendingPOIs = nil
            Logger.searchView.error("\(error.localizedDescription)")
        }
    }
}

// MARK: - ContentView

@MainActor
struct ContentView: View {

    // MARK: Properties

    @StateObject var store: ContentViewStore

    // MARK: Content

    var body: some View {
        ZStack {
            MapViewContainer(
                store: self.store.mapContainerViewStore,
                isSheetShown: self.$store.isSheetShown
            )
            .task {
                await self.store.updateMapLayers()
            }
            .task {
                await self.store.reloadPOITrending()
            }
            .ignoresSafeArea()
            .edgesIgnoringSafeArea(.all)
            .safeAreaInset(edge: .bottom) {
                if !self.store.shouldHideContent {
                    HStack(alignment: .bottom) {
                        HStack(alignment: .bottom) {
                            MapButtonsView(mapButtonsData: self.store.mapButtonData)

                            if let item = store.mapStore.nearestStreetViewScene {
                                Button {
                                    self.store.showStreetView(item)
                                } label: {
                                    Image(systemSymbol: .binoculars)
                                        .font(.title2)
                                        .padding(10)
                                        .foregroundColor(.gray)
                                        .background(Color.white)
                                        .cornerRadius(15)
                                        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
                                        .fixedSize()
                                }
                            }
                        }

                        Spacer()
                        VStack(alignment: .trailing) {
                            CurrentLocationButton(mapStore: self.store.mapStore)
                        }
                    }
                    .opacity(self.store.selectedDetent == .nearHalf ? 0 : 1)
                    .padding(.horizontal)
                }
            }
            .backport.buttonSafeArea(length: self.store.sheetSize)
            .backport.sheet(isPresented: self.$store.isSheetShown) {
                RootSheetView(
                    mapStore: self.store.mapStore,
                    searchViewStore: self.store.searchViewStore,
                    debugStore: self.store.debugStore,
                    trendingStore: self.store.trendingStore,
                    mapLayerStore: self.store.mapLayerStore,
                    sheetStore: self.store.sheetStore,
                    userLocationStore: self.store.userLocationStore,
                    sheetSize: self.$store.sheetSize,
                    navigationVisualization: self.store.navigationVisualization
                )
            }
            .safariView(item: self.$store.safariURL) { url in
                SafariView(url: url)
            }
            .onOpenURL(handler: { url in
                if let scheme = url.scheme, scheme == "https" || scheme == "http" {
                    self.store.safariURL = url
                    return .handled
                }
                return .systemAction
            })
            .environmentObject(self.store.notificationQueue)
            .simpleToast(item: self.$store.notificationQueue.currentNotification, options: .notification, onDismiss: {
                self.store.notificationQueue.removeFirst()
            }, content: {
                if let notification = store.notificationQueue.currentNotification {
                    NotificationBanner(notification: notification)
                        .padding(.horizontal, 8)
                }
            })
            VStack {
                if !self.store.shouldHideContent, self.store.notificationQueue.currentNotification == nil {
                    CategoriesBannerView(catagoryBannerData: CatagoryBannerData.cateoryBannerFakeData, searchStore: self.store.searchViewStore)
                        .presentationBackground(.thinMaterial)
                        .opacity(self.store.selectedDetent == .nearHalf ? 0 : 1)
                }
                Spacer()
            }
            .overlay(alignment: .top) {
                VStack {
                    if self.store.mapStore.streetViewScene != nil {
                        StreetView(
                            streetViewScene: self.$store.mapStore.streetViewScene,
                            mapStore: self.store.mapStore,
                            fullScreenStreetView: self.$store.fullScreenStreetView
                        )
                        .onChange(of: self.store.fullScreenStreetView) { _, newValue in
                            self.store.isSheetShown = !newValue
                        }
                    }
                }
                .onChange(of: self.store.mapStore.streetViewScene) { _, newValue in
                    self.store.isSheetShown = newValue == nil
                }
            }
            .onChange(of: self.store.selectedDetent) {
                if self.store.selectedDetent == .small {
                    Task {
                        await self.store.reloadPOITrending()
                    }
                }
            }
        }
    }

}

extension SimpleToastOptions {
    static let notification = SimpleToastOptions(alignment: .top, hideAfter: 5, modifierType: .slide)
}

// MARK: - SizePreferenceKey

struct SizePreferenceKey: PreferenceKey {

    // MARK: Static Properties

    static var defaultValue: CGSize = .zero

    // MARK: Static Functions

    // MARK: - Internal

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
