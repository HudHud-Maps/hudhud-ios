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

// MARK: - ContentView

@MainActor
struct ContentView: View {

    // MARK: Properties

    @StateObject var debugStore = DebugStore()
    @State var safariURL: URL?
    @State var safeAreaInset = UIEdgeInsets()

    @StateObject var favoritesStore = FavoritesStore()
    @StateObject var notificationManager = NotificationManager()

    // NOTE: As a workaround until Toursprung prvides us with an endpoint that services this file
    private let styleURL = URL(string: "https://static.maptoolkit.net/styles/hudhud/hudhud-default-v1.json?api_key=hudhud")! // swiftlint:disable:this force_unwrapping

    @StateObject private var notificationQueue = NotificationQueue()
    @ObservedObject private var userLocationStore: UserLocationStore
    @ObservedObject private var motionViewModel: MotionViewModel
    @ObservedObject private var searchViewStore: SearchViewStore
    @ObservedObject private var mapStore: MapStore
    @ObservedObject private var trendingStore: TrendingStore
    @ObservedObject private var mapLayerStore: HudHudMapLayerStore
    private let sheetStore: SheetStore
    private var mapViewStore: MapViewStore
    @State private var sheetSize: CGSize = .zero

    // MARK: Lifecycle

    @MainActor
    init(
        searchStore: SearchViewStore,
        mapViewStore: MapViewStore,
        sheetStore: SheetStore
    ) {
        self.searchViewStore = searchStore
        self.sheetStore = sheetStore
        self.mapStore = searchStore.mapStore
        self.userLocationStore = searchStore.mapStore.userLocationStore
        self.motionViewModel = searchStore.mapStore.motionViewModel
        self.trendingStore = TrendingStore()
        self.mapLayerStore = HudHudMapLayerStore()
        self.mapViewStore = mapViewStore
    }

    // MARK: Content

    var body: some View {
        ZStack {
            MapViewContainer(
                mapStore: self.mapStore,
                debugStore: self.debugStore,
                searchViewStore: self.searchViewStore,
                userLocationStore: self.userLocationStore,
                mapViewStore: self.mapViewStore,
                routingStore: self.searchViewStore.routingStore,
                sheetStore: self.sheetStore
            ) { sheetType in
                switch sheetType {
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
                        let freshRoutingStore = RoutingStore(mapStore: freshMapStore)
                        let tempStore = SearchViewStore(
                            mapStore: freshMapStore,
                            sheetStore: SheetStore(emptySheetType: .search),
                            routingStore: freshRoutingStore,
                            filterStore: self.searchViewStore.filterStore,
                            mode: self.searchViewStore.mode
                        )
                        tempStore.searchType = .returnPOILocation(completion: { [routingStore = self.searchViewStore.routingStore] item in
                            routingStore.add(item)
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
                    let freshRoutingStore = RoutingStore(mapStore: freshMapStore)
                    let freshSearchViewStore: SearchViewStore = {
                        let tempStore = SearchViewStore(
                            mapStore: freshMapStore,
                            sheetStore: SheetStore(emptySheetType: .search),
                            routingStore: freshRoutingStore,
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
                        sheetStore: SheetStore(emptySheetType: .search),
                        filterStore: self.searchViewStore.filterStore
                    )
                case .navigationPreview:
                    NavigationSheetView(routingStore: self.searchViewStore.routingStore, sheetStore: self.sheetStore)
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
                        self.searchViewStore.mapStore
                            .clearItems(clearResults: false)
                        self.sheetStore.popSheet()
                    }
                    .navigationBarBackButtonHidden()
                case .favoritesViewMore:
                    FavoritesViewMoreView(
                        searchStore: self.searchViewStore,
                        sheetStore: self.sheetStore,
                        favoritesStore: self.favoritesStore
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
                case .search:
                    SearchSheet(
                        mapStore: self.mapStore,
                        searchStore: self.searchViewStore,
                        trendingStore: self.trendingStore,
                        sheetStore: self.sheetStore,
                        filterStore: self.searchViewStore.filterStore
                    )
                    .background(Color(.Colors.General._05WhiteBackground))
                    .toolbar(.hidden)
                }
            }
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
            .task {
                await self.reloadPOITrending()
            }
            .ignoresSafeArea()
            .edgesIgnoringSafeArea(.all)
            .safeAreaInset(edge: .bottom) {
                if self.searchViewStore.routingStore.ferrostarCore.isNavigating == true || self.mapStore.streetViewScene != nil {
                    // hide interface during navigation and streetview

                } else {
                    HStack(alignment: .bottom) {
                        HStack(alignment: .bottom) {
                            MapButtonsView(
                                mapButtonsData: [
                                    MapButtonData(sfSymbol: .icon(.map)) {
                                        self.sheetStore.show(.mapStyle)
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
                                        self.sheetStore.show(.debugView)
                                    }
                                ]
                            )

                            if let item = self.mapStore.nearestStreetViewScene {
                                Button {
                                    self.mapStore.streetViewScene = item

                                    AppQueue.delay(0.2) {
                                        self.mapStore.zoomToStreetViewLocation()
                                    }

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
                            CurrentLocationButton(mapStore: self.mapStore)
                        }
                    }
                    .opacity(self.sheetStore.selectedDetent == .nearHalf ? 0 : 1)
                    .padding(.horizontal)
                }
            }
            .backport.buttonSafeArea(length: self.sheetSize)
            .safariView(item: self.$safariURL) { url in
                SafariView(url: url)
            }
            .onOpenURL(handler: { url in
                if let scheme = url.scheme, scheme == "https" || scheme == "http" {
                    self.safariURL = url
                    return .handled
                }
                return .systemAction
            })
            .environmentObject(self.notificationQueue)
            .simpleToast(item: self.$notificationQueue.currentNotification, options: .notification, onDismiss: {
                self.notificationQueue.removeFirst()
            }, content: {
                if let notification = self.notificationQueue.currentNotification {
                    NotificationBanner(notification: notification)
                        .padding(.horizontal, 8)
                }
            })
            VStack {
                if self.searchViewStore.routingStore.ferrostarCore.isNavigating == false, self.mapStore.streetViewScene == nil, self.notificationQueue.currentNotification.isNil {
                    CategoriesBannerView(catagoryBannerData: CatagoryBannerData.cateoryBannerFakeData, searchStore: self.searchViewStore)
                        .presentationBackground(.thinMaterial)
                        .opacity(self.sheetStore.selectedDetent == .nearHalf ? 0 : 1)
                }
                Spacer()
            }
            .overlay(alignment: .top) {
                VStack {
                    if self.mapStore.streetViewScene != nil {
                        StreetView(streetViewScene: self.$mapStore.streetViewScene, mapStore: self.mapStore, fullScreenStreetView: self.$mapStore.fullScreenStreetView)
                            .onChange(of: self.mapStore.fullScreenStreetView) { _, newValue in
                                self.sheetStore.isShown.value = !newValue
                            }
                    }
                }
                .onChange(of: self.mapStore.streetViewScene) { _, newValue in
                    self.sheetStore.isShown.value = newValue == nil
                } // I moved the if statment in VStack to allow onChange to be notified, if the onChange is inside the if statment it will not be triggered
            }
            .onChange(of: self.sheetStore.selectedDetent) {
                if self.sheetStore.selectedDetent == .small {
                    Task {
                        await self.reloadPOITrending()
                    }
                }
            }
            .onChange(of: self.mapStore.camera) {
                // we should not be storing a reference to the mapView in the map store...

                /*
                 let boundingBox = self.mapStore.mapView?.visibleCoordinateBounds
                 guard let minLongitude = boundingBox?.sw.longitude else { return }
                 guard let minLatitude = boundingBox?.sw.latitude else { return }

                 guard let maxLongitude = boundingBox?.ne.longitude else { return }
                 guard let maxLatitude = boundingBox?.ne.latitude else { return }

                 Task {
                     await self.mapStore.loadNearestStreetView(minLon: minLongitude, minLat: minLatitude, maxLon: maxLongitude, maxLat: maxLatitude)
                 }
                  */
            }
        }
    }

    // MARK: Functions

    func reloadPOITrending() async {
        do {
            let currentUserLocation = await self.userLocationStore.location(allowCached: true)?.coordinate
            let trendingPOI = try await trendingStore.getTrendingPOIs(page: 1, limit: 100, coordinates: currentUserLocation, baseURL: DebugStore().baseURL)
            self.trendingStore.trendingPOIs = trendingPOI
        } catch {
            self.trendingStore.trendingPOIs = nil
            Logger.searchView.error("\(error.localizedDescription)")
        }
    }
}

// MARK: - SimpleToastOptions

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

#Preview("Main Map") {
    ContentView(
        searchStore: .storeSetUpForPreviewing,
        mapViewStore: .storeSetUpForPreviewing,
        sheetStore: .storeSetUpForPreviewing
    )
}

#Preview("Touch Testing") {
    let store: SearchViewStore = .storeSetUpForPreviewing
    store.searchText = "shops"
    return ContentView(
        searchStore: store,
        mapViewStore: .storeSetUpForPreviewing,
        sheetStore: .storeSetUpForPreviewing
    )
}

#Preview("NavigationPreview") {
    let store: SearchViewStore = .storeSetUpForPreviewing

    let poi = ResolvedItem(id: UUID().uuidString,
                           title: "Pharmacy",
                           subtitle: "Al-Olya - Riyadh",
                           type: .hudhud,
                           coordinate: CLLocationCoordinate2D(latitude: 24.78796199972764, longitude: 46.69371856758005),
                           phone: "0503539560",
                           website: URL(string: "https://hudhud.sa"))
    store.mapStore.select(poi, shouldFocusCamera: true)
    return ContentView(
        searchStore: store,
        mapViewStore: .storeSetUpForPreviewing,
        sheetStore: .storeSetUpForPreviewing
    )
}

extension Binding where Value == Bool {

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

#Preview("Itmes") {
    let store: SearchViewStore = .storeSetUpForPreviewing

    let poi = ResolvedItem(id: UUID().uuidString,
                           title: "Half Million",
                           subtitle: "Al Takhassousi, Al Mohammadiyyah, Riyadh 12364",
                           type: .appleResolved,
                           coordinate: CLLocationCoordinate2D(latitude: 24.7332836, longitude: 46.6488895),
                           phone: "0503539560",
                           website: URL(string: "https://hudhud.sa"))
    let artwork = ResolvedItem(id: UUID().uuidString,
                               title: "Artwork",
                               subtitle: "artwork - Al-Olya - Riyadh",
                               type: .hudhud,
                               coordinate: CLLocationCoordinate2D(latitude: 24.77888564128478, longitude: 46.61555160031425),
                               phone: "0503539560",
                               website: URL(string: "https://hudhud.sa"))

    let pharmacy = ResolvedItem(id: UUID().uuidString,
                                title: "Pharmacy",
                                subtitle: "Al-Olya - Riyadh",
                                type: .hudhud,
                                coordinate: CLLocationCoordinate2D(latitude: 24.78796199972764, longitude: 46.69371856758005),
                                phone: "0503539560",
                                website: URL(string: "https://hudhud.sa"))
    store.mapStore.displayableItems = [.resolvedItem(poi), .resolvedItem(artwork), .resolvedItem(pharmacy)]
    return ContentView(
        searchStore: store,
        mapViewStore: .storeSetUpForPreviewing,
        sheetStore: .storeSetUpForPreviewing
    )
}

extension MapLayerIdentifier {
    nonisolated static let tapLayers: Set<String> = [
        Self.restaurants,
        Self.shops,
        Self.simpleCircles,
        Self.streetView,
        Self.customPOI
    ]
}

#Preview("map preview") {
    let mapStore: MapStore = .storeSetUpForPreviewing
    let searchStore: SearchViewStore = .storeSetUpForPreviewing
    MapViewContainer(
        mapStore: mapStore,
        debugStore: DebugStore(),
        searchViewStore: searchStore,
        userLocationStore: .storeSetUpForPreviewing,
        mapViewStore: .storeSetUpForPreviewing,
        routingStore: .storeSetUpForPreviewing,
        sheetStore: .storeSetUpForPreviewing
    ) { _ in EmptyView() }
}
