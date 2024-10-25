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
@Observable
final class ContentViewStore {

    // MARK: Properties

    var isSheetShown = true
    var selectedDetent: PresentationDetent = .medium
    var safariURL: URL?
    var streetViewScene: StreetViewScene?
    var fullScreenStreetView = false
    var currentNotification: Notification?
    var sheetSize: CGSize = .zero
    var mapLayers: [HudHudMapLayer]?
    var trendingPOIs: [TrendingPOI]?

    var sheetStore: SheetStore

    var mapStore: MapStore
    let searchViewStore: SearchViewStore
    let userLocationStore: UserLocationStore
    let debugStore: DebugStore
    var notificationQueue: NotificationQueue
    let trendingStore: TrendingStore
    let mapLayerStore: HudHudMapLayerStore
    let mapViewStore: MapViewStore
    let navigationVisualization: NavigationVisualization

    let mapContainerViewStore: MapViewContainerStore

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

    @State var store: ContentViewStore

    // MARK: Content

    var body: some View {
        ZStack {
            MapViewContainer(
                store: self.store.mapContainerViewStore,
                mapStore: self.store.mapStore,
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

//
// #Preview("Main Map") {
//    return ContentView(
//        searchStore: .storeSetUpForPreviewing,
//        mapViewStore: .storeSetUpForPreviewing,
//        sheetStore: SheetStore()
//    )
// }
//
// #Preview("Touch Testing") {
//    let store: SearchViewStore = .storeSetUpForPreviewing
//    store.searchText = "shops"
//    return ContentView(
//        searchStore: store,
//        mapViewStore: .storeSetUpForPreviewing,
//        sheetStore: SheetStore()
//    )
// }
//
// #Preview("NavigationPreview") {
//    let store: SearchViewStore = .storeSetUpForPreviewing
//
//    let poi = ResolvedItem(id: UUID().uuidString,
//                           title: "Pharmacy",
//                           subtitle: "Al-Olya - Riyadh",
//                           type: .hudhud,
//                           coordinate: CLLocationCoordinate2D(latitude: 24.78796199972764, longitude: 46.69371856758005),
//                           phone: "0503539560",
//                           website: URL(string: "https://hudhud.sa"))
//    store.mapStore.select(poi, shouldFocusCamera: true)
//    return ContentView(
//        searchStore: store,
//        mapViewStore: .storeSetUpForPreviewing,
//        sheetStore: SheetStore()
//    )
// }
//
// extension Binding where Value == Bool {
//
//    static func && (_ lhs: Binding<Bool>, _ rhs: Binding<Bool>) -> Binding<Bool> {
//        return Binding<Bool>(get: { lhs.wrappedValue && rhs.wrappedValue },
//                             set: { _ in })
//    }
//
//    static prefix func ! (_ binding: Binding<Bool>) -> Binding<Bool> {
//        return Binding<Bool>(
//            get: { !binding.wrappedValue },
//            set: { _ in }
//        )
//    }
// }
//
//// MARK: - Preview
//
// #Preview("Itmes") {
//    let store: SearchViewStore = .storeSetUpForPreviewing
//
//    let poi = ResolvedItem(id: UUID().uuidString,
//                           title: "Half Million",
//                           subtitle: "Al Takhassousi, Al Mohammadiyyah, Riyadh 12364",
//                           type: .appleResolved,
//                           coordinate: CLLocationCoordinate2D(latitude: 24.7332836, longitude: 46.6488895),
//                           phone: "0503539560",
//                           website: URL(string: "https://hudhud.sa"))
//    let artwork = ResolvedItem(id: UUID().uuidString,
//                               title: "Artwork",
//                               subtitle: "artwork - Al-Olya - Riyadh",
//                               type: .hudhud,
//                               coordinate: CLLocationCoordinate2D(latitude: 24.77888564128478, longitude: 46.61555160031425),
//                               phone: "0503539560",
//                               website: URL(string: "https://hudhud.sa"))
//
//    let pharmacy = ResolvedItem(id: UUID().uuidString,
//                                title: "Pharmacy",
//                                subtitle: "Al-Olya - Riyadh",
//                                type: .hudhud,
//                                coordinate: CLLocationCoordinate2D(latitude: 24.78796199972764, longitude: 46.69371856758005),
//                                phone: "0503539560",
//                                website: URL(string: "https://hudhud.sa"))
//    store.mapStore.displayableItems = [.resolvedItem(poi), .resolvedItem(artwork), .resolvedItem(pharmacy)]
//    return ContentView(searchStore: store, mapViewStore: .storeSetUpForPreviewing, sheetStore: SheetStore())
// }
//
// extension MapLayerIdentifier {
//    nonisolated static let tapLayers: Set<String> = [
//        Self.restaurants,
//        Self.shops,
//        Self.simpleCircles,
//        Self.streetView,
//        Self.customPOI
//    ]
// }
//
// #Preview("map preview") {
//    let mapStore: MapStore = .storeSetUpForPreviewing
//    let searchStore: SearchViewStore = .storeSetUpForPreviewing
//    MapViewContainer(
//        mapStore: mapStore,
//        debugStore: DebugStore(),
//        searchViewStore: searchStore,
//        userLocationStore: .storeSetUpForPreviewing,
//        mapViewStore: .storeSetUpForPreviewing,
//        routingStore: .storeSetUpForPreviewing,
//        isSheetShown: .constant(true)
//    )
// }
