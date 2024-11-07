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

    @StateObject var debugStore = DebugStore()
    @State var safariURL: URL?

    @StateObject var favoritesStore = FavoritesStore()
    @StateObject var notificationManager = NotificationManager()

    // NOTE: As a workaround until Toursprung prvides us with an endpoint that services this file
    private let styleURL = URL(string: "https://static.maptoolkit.net/styles/hudhud/hudhud-default-v1.json?api_key=hudhud")! // swiftlint:disable:this force_unwrapping

    private var mapStore: MapStore
    private var mapViewStore: MapViewStore

    @State private var streetViewStore: StreetViewStore
    @State private var sheetSize: CGSize = .zero
    private var routesPlanMapDrawer: RoutesPlanMapDrawer

    @StateObject private var notificationQueue = NotificationQueue()

    @ObservedObject private var userLocationStore: UserLocationStore
    @ObservedObject private var searchViewStore: SearchViewStore
    @ObservedObject private var trendingStore: TrendingStore
    @ObservedObject private var mapLayerStore: HudHudMapLayerStore

    @Bindable private var sheetStore: SheetStore

    @State private var navigationStore: NavigationStore

    // MARK: Lifecycle

    @MainActor
    init(searchViewStore: SearchViewStore, mapViewStore: MapViewStore, sheetStore: SheetStore, routesPlanMapDrawer: RoutesPlanMapDrawer) {
        self.searchViewStore = searchViewStore
        self.sheetStore = sheetStore
        self.mapStore = searchViewStore.mapStore
        self.userLocationStore = searchViewStore.mapStore.userLocationStore
        self.trendingStore = TrendingStore()
        self.mapLayerStore = HudHudMapLayerStore()
        self.mapViewStore = mapViewStore
        self.streetViewStore = StreetViewStore(mapStore: searchStore.mapStore)

        let tempRoutesPlanMapDrawer = RoutesPlanMapDrawer()

        self.navigationStore = NavigationStore(
            navigationEngine: NavigationEngine(configuration: .default),
            locationEngine: LocationEngine(),
            routesPlanMapDrawer: tempRoutesPlanMapDrawer
        )

        self._routesPlanMapDrawer = State(initialValue: tempRoutesPlanMapDrawer)

        self.mapViewStore.streetViewStore = self.streetViewStore
    }

    // MARK: Content

    var body: some View {
        ZStack {
            MapViewContainer(
                mapStore: self.mapStore,
                navigationStore: self.navigationStore,
                debugStore: self.debugStore,
                searchViewStore: self.searchViewStore,
                userLocationStore: self.userLocationStore,
                mapViewStore: self.mapViewStore,
                routingStore: self.searchViewStore.routingStore,
                sheetStore: self.sheetStore,
                streetViewStore: self.streetViewStore,
                routesPlanMapDrawer: self.routesPlanMapDrawer streetViewStore: self.streetViewStore,

                routesPlanMapDrawer: self.routesPlanMapDrawer
            ) { sheetType in
                switch sheetType {
                case .mapStyle:
                    MapLayersView(mapStore: self.mapStore, sheetStore: self.sheetStore, hudhudMapLayerStore: self.mapLayerStore)
                        .navigationBarBackButtonHidden()
                        .presentationCornerRadius(21)
                case .debugView:
                    DebugMenuView(debugSettings: self.debugStore, sheetStore: self.sheetStore)
                        .onDisappear(perform: {
                            self.sheetStore.popToRoot()
                        })
                        .navigationBarBackButtonHidden()
                case let .navigationAddSearchView(onAddItem):
                    // Initialize fresh instances of MapStore and SearchViewStore
                    let freshMapStore = MapStore(userLocationStore: .storeSetUpForPreviewing)
                    let freshSearchViewStore: SearchViewStore = {
                        let freshRoutingStore = RoutingStore(mapStore: freshMapStore, routesPlanMapDrawer: RoutesPlanMapDrawer())
                        let tempStore = SearchViewStore(
                            mapStore: freshMapStore,
                            sheetStore: SheetStore(emptySheetType: .search),
                            routingStore: freshRoutingStore,
                            filterStore: self.searchViewStore.filterStore,
                            mode: self.searchViewStore.mode
                        )
                        tempStore.searchType = .returnPOILocation(completion: onAddItem)
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
                    let freshMapStore = MapStore(userLocationStore: .storeSetUpForPreviewing)
                    let freshRoutingStore = RoutingStore(mapStore: freshMapStore, routesPlanMapDrawer: RoutesPlanMapDrawer())
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
                        pointOfInterestStore: PointOfInterestStore(
                            pointOfInterest: item,
                            mapStore: self.mapStore,
                            sheetStore: self.sheetStore
                        ), sheetStore: self.sheetStore,
                        routingStore: self.searchViewStore.routingStore,
                        didDenyLocationPermission: self.userLocationStore.permissionStatus.didDenyLocationPermission
                    ) { routeIfAvailable in
                        Logger.searchView.info("Start item \(item)")
                        if self.debugStore.enableNewRoutePlanner {
                            self.sheetStore.show(.routePlanner(RoutePlannerStore(
                                sheetStore: self.sheetStore,
                                userLocationStore: self.userLocationStore,
                                mapStore: self.mapStore,
                                routingStore: self.searchViewStore.routingStore,
                                routesPlanMapDrawer: self.routesPlanMapDrawer,
                                destination: item
                            )))
                            return
                        }
                        Task {
                            do {
                                try await self.searchViewStore.routingStore.showRoutes(
                                    to: item,
                                    with: routeIfAvailable
                                )
                                try await self.notificationManager.requestAuthorization()
                                self.sheetStore.show(.navigationPreview)
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
                case let .routePlanner(store):
                    RoutePlannerView(routePlannerStore: store)
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
                        favoritesStore: self.favoritesStore,
                        sheetStore: self.sheetStore
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
                if self.navigationStore.state.isNavigating == true || self.streetViewStore.streetViewScene != nil {
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

                            if (self.mapStore.mapViewPort?.zoom ?? 0) > 10,
                               let item = self.streetViewStore.nearestStreetViewScene {
                                Button {
                                    self.streetViewStore.streetViewScene = item
                                    self.streetViewStore.zoomToStreetViewLocation()
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
                    .opacity(self.sheetStore.shouldHideMapButtons ? 0 : 1)
                    .padding(.horizontal)
                    .offset(y: -(self.sheetStore.sheetHeight + 8))
                    .animation(.easeInOut(duration: 0.2), value: self.sheetStore.sheetHeight)
                }
            }
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
                if self.navigationStore.state.isNavigating == false, self.streetViewStore.streetViewScene == nil, self.notificationQueue.currentNotification.isNil {
                    CategoriesBannerView(catagoryBannerData: CatagoryBannerData.cateoryBannerFakeData, searchStore: self.searchViewStore)
                        .presentationBackground(.thinMaterial)
                        .opacity(self.sheetStore.selectedDetent == .nearHalf ? 0 : 1)
                }
                Spacer()
            }
            .overlay(alignment: .top) {
                self.streetView
            }
            .onChange(of: self.sheetStore.selectedDetent) {
                if self.sheetStore.selectedDetent == .small {
                    Task {
                        await self.reloadPOITrending()
                    }
                }
            }
            .onChange(of: self.mapStore.mapViewPort) {
                // we should not be storing a reference to the mapView in the map store...
                guard let viewport = self.mapStore.mapViewPort else { return }

                let boundingBox = viewport.calculateBoundingBox(viewWidth: 400, viewHeight: 800)
                let minLongitude = boundingBox.southEast.longitude
                let minLatitude = boundingBox.southEast.latitude
                let maxLongitude = boundingBox.northWest.longitude
                let maxLatitude = boundingBox.northWest.latitude

                Task {
                    await self.streetViewStore.loadNearestStreetView(minLon: minLongitude, minLat: minLatitude, maxLon: maxLongitude, maxLat: maxLatitude)
                }
            }
        }
    }

    var streetView: some View {
        VStack {
            if self.streetViewStore.streetViewScene != nil {
                StreetView(store: self.streetViewStore, debugStore: self.debugStore)
            }
        }
        .onChange(of: self.streetViewStore.streetViewScene) { _, _ in
            self.updateSearchShown()
        }
        .onChange(of: self.streetViewStore.fullScreenStreetView) { _, _ in
            self.updateSearchShown()
        }
    }
}

private extension ContentView {

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

    func updateSearchShown() {
        self.sheetStore.isShown.value = !self.streetViewStore.fullScreenStreetView && self.streetViewStore.streetViewScene.isNil
    }
}

// MARK: - SimpleToastOptions

extension SimpleToastOptions {
    static let notification = SimpleToastOptions(alignment: .top, hideAfter: 5, modifierType: .slide)
}

private extension MapViewPort {

    func calculateBoundingBox(viewWidth: CGFloat, viewHeight: CGFloat) -> (northWest: CLLocationCoordinate2D, southEast: CLLocationCoordinate2D) {
        // Earth's circumference in meters
        let earthCircumference: Double = 40_075_016.686

        // Meters per pixel at given zoom level
        let metersPerPixel = earthCircumference / pow(2.0, self.zoom + 8)

        // Calculate the span in meters
        let spanX = Double(viewWidth) * metersPerPixel
        let spanY = Double(viewHeight) * metersPerPixel

        // Convert the latitude to radians
        let latInRad = self.center.latitude * .pi / 180.0

        // Calculate the latitude and longitude span
        let latitudeSpan = (spanY / 2) / 111_320.0
        let longitudeSpan = (spanX / 2) / (111_320.0 * cos(latInRad))

        // North-west (top-left) coordinate
        let northWest = CLLocationCoordinate2D(latitude: self.center.latitude + latitudeSpan,
                                               longitude: self.center.longitude - longitudeSpan)

        // South-east (bottom-right) coordinate
        let southEast = CLLocationCoordinate2D(latitude: self.center.latitude - latitudeSpan,
                                               longitude: self.center.longitude + longitudeSpan)

        return (northWest, southEast)
    }
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

// MARK: - Previews

#Preview("Main Map") {
    ContentView(searchViewStore: .storeSetUpForPreviewing,
                mapViewStore: .storeSetUpForPreviewing,
                sheetStore: .storeSetUpForPreviewing,
                routesPlanMapDrawer: RoutesPlanMapDrawer())
}

#Preview("Touch Testing") {
    let store: SearchViewStore = .storeSetUpForPreviewing
    store.searchText = "shops"
    return ContentView(searchViewStore: store,
                       mapViewStore: .storeSetUpForPreviewing,
                       sheetStore: .storeSetUpForPreviewing,
                       routesPlanMapDrawer: RoutesPlanMapDrawer())
}

#Preview("NavigationPreview") {
    let poi = ResolvedItem(id: UUID().uuidString,
                           title: "Pharmacy",
                           subtitle: "Al-Olya - Riyadh",
                           type: .hudhud,
                           coordinate: CLLocationCoordinate2D(latitude: 24.78796199972764, longitude: 46.69371856758005),
                           phone: "0503539560",
                           website: URL(string: "https://hudhud.sa"))

    let userLocationStore = UserLocationStore(location: .storeSetUpForPreviewing)
    let mapStore = MapStore(camera: .center(poi.coordinate, zoom: 14), userLocationStore: userLocationStore)
    let sheetStore = SheetStore(emptySheetType: .pointOfInterest(poi))
    let mapViewStore = MapViewStore(mapStore: mapStore, sheetStore: sheetStore)
    let routesPlanMapDrawer = RoutesPlanMapDrawer()
    let routingStore = RoutingStore(mapStore: mapStore, routesPlanMapDrawer: routesPlanMapDrawer)

    let searchViewStore = SearchViewStore(mapStore: mapStore,
                                          sheetStore: sheetStore,
                                          routingStore: routingStore,
                                          filterStore: FilterStore(),
                                          mode: .preview)

    let url = Bundle.main.url(forResource: "riyadh-pharmacy-route", withExtension: "json")! // swiftlint:disable:this force_unwrapping
    let data = try! Data(contentsOf: url) // swiftlint:disable:this force_try
    let parser = createOsrmResponseParser(polylinePrecision: 6)
    let routes = try! parser.parseResponse(response: data) // swiftlint:disable:this force_try

    if let route = routes.first {
        routingStore.routes = routes
        routingStore.selectRoute(withId: route.id)
    }

    return ContentView(searchViewStore: searchViewStore,
                       mapViewStore: mapViewStore,
                       sheetStore: sheetStore,
                       routesPlanMapDrawer: routesPlanMapDrawer)
}

// MARK: - Preview

#Preview("Items") {
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
    return ContentView(searchViewStore: store,
                       mapViewStore: .storeSetUpForPreviewing,
                       sheetStore: .storeSetUpForPreviewing,
                       routesPlanMapDrawer: RoutesPlanMapDrawer())
}
