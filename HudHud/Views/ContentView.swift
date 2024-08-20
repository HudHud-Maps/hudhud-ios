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
import MapboxCoreNavigation
import MapboxDirections
import MapboxNavigation
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

// MARK: - SheetSubView

enum SheetSubView: Hashable, Codable {
    case mapStyle, debugView, navigationAddSearchView, favorites
}

// MARK: - ContentView

@MainActor
struct ContentView: View {

    // NOTE: As a workaround until Toursprung prvides us with an endpoint that services this file
    private let styleURL = URL(string: "https://static.maptoolkit.net/styles/hudhud/hudhud-default-v1.json?api_key=hudhud")! // swiftlint:disable:this force_unwrapping

    @StateObject private var notificationQueue = NotificationQueue()
    @ObservedObject private var motionViewModel: MotionViewModel
    @ObservedObject private var searchViewStore: SearchViewStore
    @ObservedObject private var mapStore: MapStore
    @ObservedObject private var trendingStore: TrendingStore
    @ObservedObject private var mapLayerStore: HudHudMapLayerStore

    @State private var sheetSize: CGSize = .zero

    @StateObject var debugStore = DebugStore()
    @State var safariURL: URL?

    var body: some View {
        ZStack {
            MapViewContainer(
                mapStore: self.mapStore,
                debugStore: self.debugStore,
                searchViewStore: self.searchViewStore,
                sheetSize: self.sheetSize
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
            .task {
                await self.reloadPOITrending()
            }
            .ignoresSafeArea()
            .edgesIgnoringSafeArea(.all)
            .safeAreaInset(edge: .bottom) {
                if self.mapStore.navigationProgress == .none, self.mapStore.streetViewScene == nil {
                    HStack(alignment: .bottom) {
                        HStack(alignment: .bottom) {
                            MapButtonsView(mapButtonsData: [
                                MapButtonData(sfSymbol: .icon(.map)) {
                                    self.mapStore.path.append(SheetSubView.mapStyle)
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
                                    self.mapStore.path.append(SheetSubView.debugView)
                                }
                            ])

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
                    .opacity(self.mapStore.selectedDetent == .nearHalf ? 0 : 1)
                    .padding(.horizontal)
                }
            }
            .backport.buttonSafeArea(length: self.sheetSize)
            .backport.sheet(isPresented: self.$mapStore.searchShown && Binding<Bool>(
                get: { self.mapStore.navigationProgress == .none || self.mapStore.navigationProgress == .feedback },
                set: { _ in }
            )) {
                RootSheetView(mapStore: self.mapStore, searchViewStore: self.searchViewStore, debugStore: self.debugStore, trendingStore: self.trendingStore, mapLayerStore: self.mapLayerStore, sheetSize: self.$sheetSize)
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
                if self.mapStore.navigationProgress == .none, self.mapStore.streetViewScene == nil, self.notificationQueue.currentNotification.isNil {
                    CategoriesBannerView(catagoryBannerData: CatagoryBannerData.cateoryBannerFakeData, searchStore: self.searchViewStore)
                        .presentationBackground(.thinMaterial)
                        .opacity(self.mapStore.selectedDetent == .nearHalf ? 0 : 1)
                }
                Spacer()
            }
            .overlay(alignment: .top) {
                VStack {
                    if self.mapStore.streetViewScene != nil {
                        StreetView(streetViewScene: self.$mapStore.streetViewScene, mapStore: self.mapStore, fullScreenStreetView: self.$mapStore.fullScreenStreetView)
                            .onChange(of: self.mapStore.fullScreenStreetView) { newValue in
                                self.mapStore.searchShown = !newValue
                            }
                    }
                }
                .onChange(of: self.mapStore.streetViewScene) { newValue in
                    self.mapStore.searchShown = newValue == nil
                } // I moved the if statment in VStack to allow onChange to be notified, if the onChange is inside the if statment it will not be triggered
            }
            .onChange(of: self.mapStore.selectedDetent) { _ in
                if self.mapStore.selectedDetent == .small {
                    Task {
                        await self.reloadPOITrending()
                    }
                }
            }
            .onChange(of: self.mapStore.camera) { _ in

                let boundingBox = self.mapStore.mapView?.visibleCoordinateBounds
                guard let minLongitude = boundingBox?.sw.longitude else { return }
                guard let minLatitude = boundingBox?.sw.latitude else { return }

                guard let maxLongitude = boundingBox?.ne.longitude else { return }
                guard let maxLatitude = boundingBox?.ne.latitude else { return }

                Task {
                    await self.mapStore.loadNearestStreetView(minLon: minLongitude, minLat: minLatitude, maxLon: maxLongitude, maxLat: maxLatitude)
                }
            }
        }
    }

    func reloadPOITrending() async {
        do {
            let trendingPOI = try await trendingStore.getTrendingPOIs(page: 1, limit: 100, coordinates: self.mapStore.currentLocation, baseURL: DebugStore().baseURL)
            self.trendingStore.trendingPOIs = trendingPOI
        } catch {
            self.trendingStore.trendingPOIs = nil
            Logger.searchView.error("\(error.localizedDescription)")
        }
    }

    // MARK: - Lifecycle

    @MainActor
    init(searchStore: SearchViewStore) {
        self.searchViewStore = searchStore
        self.mapStore = searchStore.mapStore
        self.motionViewModel = searchStore.mapStore.motionViewModel
        self.trendingStore = TrendingStore()
        self.mapLayerStore = HudHudMapLayerStore()
        self.mapStore.routes = searchStore.mapStore.routes
    }

}

// MARK: - SimpleToastOptions

extension SimpleToastOptions {
    static let notification = SimpleToastOptions(alignment: .top, hideAfter: 5, modifierType: .slide)
}

// MARK: - SizePreferenceKey

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    // MARK: - Internal

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

#Preview("Main Map") {
    let searchViewStore: SearchViewStore = .storeSetUpForPreviewing
    return ContentView(searchStore: searchViewStore)
}

#Preview("Touch Testing") {
    let store: SearchViewStore = .storeSetUpForPreviewing
    store.searchText = "shops"
    return ContentView(searchStore: store)
}

#Preview("NavigationPreview") {
    let store: SearchViewStore = .storeSetUpForPreviewing

    let poi = ResolvedItem(id: UUID().uuidString,
                           title: "Pharmacy",
                           subtitle: "Al-Olya - Riyadh",
                           type: .hudhud,
                           coordinate: CLLocationCoordinate2D(latitude: 24.78796199972764, longitude: 46.69371856758005),
                           color: .systemRed,
                           phone: "0503539560",
                           website: URL(string: "https://hudhud.sa"))
    store.mapStore.selectedItem = poi
    return ContentView(searchStore: store)
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

// MARK: - NavigationViewController + MapViewHostViewController

extension NavigationViewController: MapViewHostViewController {
    public typealias MapType = NavigationMapView
}

// MARK: - Preview

#Preview("Itmes") {
    let store: SearchViewStore = .storeSetUpForPreviewing

    let poi = ResolvedItem(id: UUID().uuidString,
                           title: "Half Million",
                           subtitle: "Al Takhassousi, Al Mohammadiyyah, Riyadh 12364",
                           type: .appleResolved,
                           coordinate: CLLocationCoordinate2D(latitude: 24.7332836, longitude: 46.6488895),
                           color: .systemRed,
                           phone: "0503539560",
                           website: URL(string: "https://hudhud.sa"))
    let artwork = ResolvedItem(id: UUID().uuidString,
                               title: "Artwork",
                               subtitle: "artwork - Al-Olya - Riyadh",
                               type: .hudhud,
                               coordinate: CLLocationCoordinate2D(latitude: 24.77888564128478, longitude: 46.61555160031425),
                               color: .systemRed,
                               phone: "0503539560",
                               website: URL(string: "https://hudhud.sa"))

    let pharmacy = ResolvedItem(id: UUID().uuidString,
                                title: "Pharmacy",
                                subtitle: "Al-Olya - Riyadh",
                                type: .hudhud,
                                coordinate: CLLocationCoordinate2D(latitude: 24.78796199972764, longitude: 46.69371856758005),
                                color: .systemRed,
                                phone: "0503539560",
                                website: URL(string: "https://hudhud.sa"))
    store.mapStore.displayableItems = [.resolvedItem(poi), .resolvedItem(artwork), .resolvedItem(pharmacy)]
    return ContentView(searchStore: store)
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
    return MapViewContainer(mapStore: mapStore, debugStore: DebugStore(), searchViewStore: searchStore, sheetSize: CGSize(size: 0))
}
