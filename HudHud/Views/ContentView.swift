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

    @State private var showUserLocation: Bool = false
    @State private var sheetSize: CGSize = .zero
    @State private var didTryToZoomOnUsersLocation = false

    @StateObject var debugStore = DebugStore()
    var mapViewStore: MapViewStore
    @State var safariURL: URL?

    @ViewBuilder
    var mapView: some View {
        MapView<NavigationViewController>(makeViewController: {
            let viewController = NavigationViewController(dayStyle: CustomDayStyle(), nightStyle: CustomNightStyle())
            viewController.showsEndOfRouteFeedback = false // We show our own Feedback
            viewController.mapView.compassViewMargins.y = 50
            return viewController
        }(), styleURL: self.mapStore.mapStyleUrl(), camera: self.$mapStore.camera) {
            // Display preview data as a polyline on the map
            if let route = self.mapStore.routes?.routes.first, self.mapStore.navigationProgress == .none {
                let polylineSource = ShapeSource(identifier: MapSourceIdentifier.pedestrianPolyline) {
                    MLNPolylineFeature(coordinates: route.coordinates ?? [])
                }

                // Add a polyline casing for a stroke effect
                LineStyleLayer(identifier: MapLayerIdentifier.routeLineCasing, source: polylineSource)
                    .lineCap(.round)
                    .lineJoin(.round)
                    .lineColor(.white)
                    .lineWidth(interpolatedBy: .zoomLevel,
                               curveType: .linear,
                               parameters: NSExpression(forConstantValue: 1.5),
                               stops: NSExpression(forConstantValue: [18: 14, 20: 26]))

                // Add an inner (blue) polyline
                LineStyleLayer(identifier: MapLayerIdentifier.routeLineInner, source: polylineSource)
                    .lineCap(.round)
                    .lineJoin(.round)
                    .lineColor(.systemBlue)
                    .lineWidth(interpolatedBy: .zoomLevel,
                               curveType: .linear,
                               parameters: NSExpression(forConstantValue: 1.5),
                               stops: NSExpression(forConstantValue: [18: 11, 20: 18]))

                let routePoints = self.mapStore.routePoints

                CircleStyleLayer(identifier: MapLayerIdentifier.simpleCirclesRoute, source: routePoints)
                    .radius(16)
                    .color(.systemRed)
                    .strokeWidth(2)
                    .strokeColor(.white)
                SymbolStyleLayer(identifier: MapLayerIdentifier.simpleSymbolsRoute, source: routePoints)
                    .iconImage(UIImage(systemSymbol: .mappin).withRenderingMode(.alwaysTemplate))
                    .iconColor(.white)
            }

            if self.debugStore.customMapSymbols == true {
                SymbolStyleLayer(identifier: "patPOI", source: MLNSource(identifier: "hpoi"), sourceLayerIdentifier: "public.poi")
                    .iconImage(mappings: SFSymbolSpriteSheet.spriteMapping, default: SFSymbolSpriteSheet.defaultMapPin)
                    .iconAllowsOverlap(false)
                    .text(featurePropertyNamed: "name_en")
                    .textFontSize(11)
                    .maximumTextWidth(8.0)
                    .textHaloColor(UIColor.white)
                    .textHaloWidth(1.0)
                    .textHaloBlur(0.5)
                    .textAnchor("top")
                    .textColor(expression: SFSymbolSpriteSheet.colorExpression)
                    .textOffset(CGVector(dx: 0, dy: 1.2))
                    .minimumZoomLevel(13.0)
                    .maximumZoomLevel(22.0)
            }

            let pointSource = self.mapStore.points

            // shows the clustered pins
            CircleStyleLayer(identifier: MapLayerIdentifier.simpleCirclesClustered, source: pointSource)
                .radius(16)
                .color(.systemRed)
                .strokeWidth(2)
                .strokeColor(.white)
                .predicate(NSPredicate(format: "cluster == YES"))
            SymbolStyleLayer(identifier: MapLayerIdentifier.simpleSymbolsClustered, source: pointSource)
                .textColor(.white)
                .text(expression: NSExpression(format: "CAST(point_count, 'NSString')"))
                .predicate(NSPredicate(format: "cluster == YES"))

            // shows the unclustered pins
            if self.mapStore.navigationProgress != .navigating {
                CircleStyleLayer(identifier: MapLayerIdentifier.simpleCircles, source: pointSource)
                    .radius(16)
                    .color(.systemRed)
                    .strokeWidth(2)
                    .strokeColor(.white)
                    .predicate(NSPredicate(format: "cluster != YES"))
                SymbolStyleLayer(identifier: MapLayerIdentifier.simpleSymbols, source: pointSource)
                    .iconImage(UIImage(systemSymbol: .mappin).withRenderingMode(.alwaysTemplate))
                    .iconColor(.white)
                    .predicate(NSPredicate(format: "cluster != YES"))
            }
            // shows the selected pin
            CircleStyleLayer(
                identifier: MapLayerIdentifier.selectedCircle,
                source: self.mapStore.selectedPoint
            )
            .radius(30)
            .color(UIColor(self.mapStore.selectedItem?.color ?? Color(.systemRed)))
            .strokeWidth(2)
            .strokeColor(.white)
            .predicate(NSPredicate(format: "cluster != YES"))
            SymbolStyleLayer(
                identifier: MapLayerIdentifier.selectedCircleIcon,
                source: self.mapStore.selectedPoint
            )
            .iconImage(UIImage(systemSymbol: self.mapStore.selectedItem?.symbol ?? .mappin, withConfiguration: UIImage.SymbolConfiguration(pointSize: 24)).withRenderingMode(.alwaysTemplate))
            .iconColor(.white)
            .predicate(NSPredicate(format: "cluster != YES"))
        }
        .onTapMapGesture(on: MapLayerIdentifier.tapLayers) { _, features in
            if self.mapStore.navigationProgress == .feedback {
                self.searchViewStore.endTrip()
                return
            }
            self.mapViewStore.didTapOnMap(containing: features)
        }
        .expandClustersOnTapping(clusteredLayers: [ClusterLayer(layerIdentifier: MapLayerIdentifier.simpleCirclesClustered, sourceIdentifier: MapSourceIdentifier.points)])
        .unsafeMapViewControllerModifier { controller in
            controller.delegate = self.mapStore

            switch self.mapStore.navigationProgress {
            case .none:
                if let route = self.mapStore.navigatingRoute {
                    if self.debugStore.simulateRide {
                        let locationManager = SimulatedLocationManager(route: route)
                        locationManager.speedMultiplier = 2
                        controller.startNavigation(with: route, animated: true, locationManager: locationManager)
                    } else {
                        controller.startNavigation(with: route, animated: true)
                    }
                    self.mapStore.navigationProgress = .navigating
                } else {
                    controller.mapView.userTrackingMode = self.mapStore.trackingState == .keepTracking ? .followWithCourse : .none
                    controller.mapView.showsUserLocation = self.showUserLocation && self.mapStore.streetViewScene == nil
                }
            case .navigating:
                if let route = self.mapStore.navigatingRoute {
                    controller.route = route
                } else {
                    controller.endNavigation()
                    self.mapStore.navigationProgress = .feedback
                }
            case .feedback:
                break
            }
        }
        .cameraModifierDisabled(self.mapStore.navigatingRoute != nil)
        .onLongPressMapGesture(onPressChanged: { mapGesture in
            if self.searchViewStore.mapStore.selectedItem == nil {
                let selectedItem = ResolvedItem(id: UUID().uuidString, title: "Dropped Pin", subtitle: "", type: .hudhud, coordinate: mapGesture.coordinate, color: .systemRed)
                self.searchViewStore.mapStore.selectedItem = selectedItem
                self.mapStore.selectedDetent = .third
            }
        })
        .backport.safeAreaPadding(.bottom, self.mapStore.searchShown ? self.sheetPaddingSize() : 0)
        .onChange(of: self.mapStore.routes) { newRoute in
            if let routeUnwrapped = newRoute {
                if let route = routeUnwrapped.routes.first, let coordinates = route.coordinates, !coordinates.isEmpty {
                    if let camera = CameraState.boundingBox(from: coordinates) {
                        self.mapStore.camera = camera
                    }
                }
            }
        }
        .onChange(of: self.mapStore.selectedDetent) { _ in
            if self.mapStore.selectedDetent == .small {
                Task {
                    await self.reloadPOITrending()
                }
            }
        }
        .gesture(
            DragGesture()
                .onChanged { _ in
                    if self.mapStore.trackingState != .none {
                        self.mapStore.trackingState = .none
                    }
                }
        )
    }

    var body: some View {
        ZStack {
            self.mapView
                .task {
                    for await event in await Location.forSingleRequestUsage.startMonitoringAuthorization() {
                        Logger.searchView.debug("Authorization status did change: \(event.authorizationStatus, align: .left(columns: 10))")
                        self.showUserLocation = event.authorizationStatus.allowed
                    }
                }
                .task {
                    self.showUserLocation = Location.forSingleRequestUsage.authorizationStatus.allowed
                    Logger.searchView.debug("Authorization status authorizedAllowed")
                }
                .task {
                    do {
                        guard self.didTryToZoomOnUsersLocation == false else {
                            return
                        }
                        self.didTryToZoomOnUsersLocation = true
                        let userLocation = try await Location.forSingleRequestUsage.requestLocation()
                        var coordinates: CLLocationCoordinate2D? = userLocation.location?.coordinate
                        if coordinates == nil {
                            // fall back to any location that was found, even if bad
                            // accuracy
                            coordinates = Location.forSingleRequestUsage.lastLocation?.coordinate
                        }
                        guard let coordinates else {
                            Logger.currentLocation.debug("Could not determine user location, will not zoom...")
                            return
                        }
                        if self.mapStore.currentLocation != coordinates {
                            self.mapStore.currentLocation = coordinates
                        }
                    } catch {
                        Logger.currentLocation.error("location error: \(error)")
                    }
                }
                .task {
                    do {
                        let mapLayers = try await mapLayerStore.getMaplayers()
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
        self.mapViewStore = MapViewStore(mapStore: searchStore.mapStore)
        self.mapStore.routes = searchStore.mapStore.routes
    }

    // MARK: - Internal

    func reloadPOITrending() async {
        do {
            let trendingPOI = try await trendingStore.getTrendingPOIs(page: 1, limit: 100, coordinates: self.mapStore.currentLocation)
            self.trendingStore.trendingPOIs = trendingPOI
        } catch {
            self.trendingStore.trendingPOIs = nil
            Logger.searchView.error("\(error.localizedDescription)")
        }
    }

    func sheetPaddingSize() -> Double {
        if self.sheetSize.height > 80 {
            return 80
        } else {
            return self.sheetSize.height
        }
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

// MARK: - NavigationViewController + WrappedViewController

extension NavigationViewController: WrappedViewController {
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
        Self.streetView
    ]
}
