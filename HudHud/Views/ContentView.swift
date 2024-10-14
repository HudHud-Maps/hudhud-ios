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

// MARK: - SheetSubView

enum SheetSubView: Hashable, Codable {
    case mapStyle, debugView, navigationAddSearchView, favorites, navigationPreview
}

// MARK: - ContentView

@MainActor
struct ContentView: View {

    // MARK: Properties

    @StateObject var debugStore = DebugStore()
    @State var safariURL: URL?
    @State var safeAreaInset = UIEdgeInsets()

    // NOTE: As a workaround until Toursprung prvides us with an endpoint that services this file
    private let styleURL = URL(string: "https://static.maptoolkit.net/styles/hudhud/hudhud-default-v1.json?api_key=hudhud")! // swiftlint:disable:this force_unwrapping

    @StateObject private var notificationQueue = NotificationQueue()
    @ObservedObject private var userLocationStore: UserLocationStore
    @ObservedObject private var searchViewStore: SearchViewStore
    @ObservedObject private var mapStore: MapStore
    @ObservedObject private var trendingStore: TrendingStore
    @ObservedObject private var mapLayerStore: HudHudMapLayerStore
    @ObservedObject private var mapViewStore: MapViewStore
    @State private var sheetSize: CGSize = .zero

    // MARK: Lifecycle

    @MainActor
    init(searchStore: SearchViewStore, mapViewStore: MapViewStore) {
        self.searchViewStore = searchStore
        self.mapStore = searchStore.mapStore
        self.userLocationStore = searchStore.mapStore.userLocationStore
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
                mapViewStore: self.mapViewStore
            )
            .task {
                await refreshMapLayers()
            }
            .onReceive(
                NotificationCenter
                    .default
                    .publisher(for: UIApplication.willEnterForegroundNotification)
            ) { _ in
                Task {
                    await refreshMapLayers()
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
                            MapButtonsView(mapButtonsData: [
                                MapButtonData(sfSymbol: .icon(.map)) {
                                    self.mapViewStore.path.append(SheetSubView.mapStyle)
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
                                    self.mapViewStore.path.append(SheetSubView.debugView)
                                }
                            ])

                            if let item = self.mapStore.nearestStreetViewScene {
                                Button {
                                    self.mapStore.streetViewScene = item
                                    self.mapStore.zoomToStreetViewLocation()
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
                    .opacity(self.mapViewStore.selectedDetent == .nearHalf ? 0 : 1)
                    .padding(.horizontal)
                }
            }
            .backport.buttonSafeArea(length: self.sheetSize)
            .backport.sheet(isPresented: self.$mapStore.searchShown) {
                RootSheetView(mapStore: self.mapStore, searchViewStore: self.searchViewStore, debugStore: self.debugStore, trendingStore: self.trendingStore, mapLayerStore: self.mapLayerStore, mapViewStore: self.mapViewStore, userLocationStore: self.userLocationStore, sheetSize: self.$sheetSize)
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
                if self.searchViewStore.routingStore.ferrostarCore.isNavigating == false, self.mapStore.streetViewScene == nil, self.notificationQueue.currentNotification.isNil {
                    CategoriesBannerView(catagoryBannerData: CatagoryBannerData.cateoryBannerFakeData, searchStore: self.searchViewStore)
                        .presentationBackground(.thinMaterial)
                        .opacity(self.mapViewStore.selectedDetent == .nearHalf ? 0 : 1)
                }
                Spacer()
            }
            .overlay(alignment: .top) {
                VStack {
                    if self.mapStore.streetViewScene != nil {
                        StreetView(streetViewScene: self.$mapStore.streetViewScene, fullScreenStreetView: self.$mapStore.fullScreenStreetView, mapStore: self.mapStore)
                            .onChange(of: self.mapStore.fullScreenStreetView) { _, newValue in
                                self.mapStore.searchShown = !newValue
                            }
                    }
                }
                .onChange(of: self.mapStore.streetViewScene) { _, newValue in
                    self.mapStore.searchShown = newValue == nil
                } // I moved the if statment in VStack to allow onChange to be notified, if the onChange is inside the if statment it will not be triggered
            }
            .onChange(of: self.mapViewStore.selectedDetent) {
                if self.mapViewStore.selectedDetent == .small {
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
                    await self.mapStore.loadNearestStreetView(minLon: minLongitude, minLat: minLatitude, maxLon: maxLongitude, maxLat: maxLatitude)
                }
            }
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

    func refreshMapLayers() async {
        do {
            let mapLayers = try await mapLayerStore.getMaplayers(baseURL: DebugStore().baseURL)
            self.mapLayerStore.hudhudMapLayers = mapLayers
            self.mapStore.updateCurrentMapStyle(mapLayers: mapLayers)
        } catch {
            self.mapLayerStore.hudhudMapLayers = nil
            Logger.searchView.error("Map layers fetching failed due to: \(error.localizedDescription)")
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
        let northWest = CLLocationCoordinate2D(
            latitude: self.center.latitude + latitudeSpan,
            longitude: self.center.longitude - longitudeSpan
        )

        // South-east (bottom-right) coordinate
        let southEast = CLLocationCoordinate2D(
            latitude: self.center.latitude - latitudeSpan,
            longitude: self.center.longitude + longitudeSpan
        )

        return (northWest, southEast)
    }
}

#Preview("Main Map") {
    return ContentView(searchStore: .storeSetUpForPreviewing, mapViewStore: .storeSetUpForPreviewing)
}

#Preview("Touch Testing") {
    let store: SearchViewStore = .storeSetUpForPreviewing
    store.searchText = "shops"
    return ContentView(searchStore: store, mapViewStore: .storeSetUpForPreviewing)
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
    return ContentView(searchStore: store, mapViewStore: .storeSetUpForPreviewing)
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
    return ContentView(searchStore: store, mapViewStore: .storeSetUpForPreviewing)
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
    MapViewContainer(mapStore: mapStore, debugStore: DebugStore(), searchViewStore: searchStore, userLocationStore: .storeSetUpForPreviewing, mapViewStore: .storeSetUpForPreviewing)
}
