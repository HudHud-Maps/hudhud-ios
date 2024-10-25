//
//  MapViewContainer.swift
//  HudHud
//
//  Created by Alaa . on 05/08/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import Combine
import FerrostarCore
import FerrostarCoreFFI
import FerrostarMapLibreUI
import FerrostarSwiftUI
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import SwiftUI

typealias POI = ResolvedItem

// MARK: - MapViewContainerStore

@MainActor
@Observable
final class MapViewContainerStore {

    // MARK: Properties

    var mapViewStore: MapViewStore
    var mapStore: MapStore
    let debugStore: DebugStore
    let searchViewStore: SearchViewStore
    let userLocationStore: UserLocationStore
    let navigationVisualization: NavigationVisualization

    var routes: [Route] = []
    var selectedRoute: Route?

    let mapViewController = MLNMapViewController()

    let locationManager: MLNLocationManager

    private var cancellables: Set<AnyCancellable> = []

    // MARK: Computed Properties

    var styleURL: URL {
//        let styleURL = Bundle.main.url(forResource: "style", withExtension: "json")!
//        return styleURL
        self.mapStore.mapStyleUrl()
    }

    var lastLocation: CLLocation? {
        self.navigationVisualization.lastLocation
    }

    var locationPermissionStatus: UserLocationStore.PermissionStatus {
        self.userLocationStore.permissionStatus
    }

    // MARK: Lifecycle

    init(
        navigationVisualization: NavigationVisualization,
        mapViewStore: MapViewStore,
        mapStore: MapStore,
        debugStore: DebugStore,
        searchViewStore: SearchViewStore,
        userLocationStore: UserLocationStore
    ) {
        self.navigationVisualization = navigationVisualization
        self.mapViewStore = mapViewStore
        self.mapStore = mapStore
        self.debugStore = debugStore
        self.searchViewStore = searchViewStore
        self.userLocationStore = userLocationStore

        self.locationManager = LocationManagerProxy(locationProvider: navigationVisualization.locationprovider)

        self.listenForNavigationVisualizationEvents()
    }

    // MARK: Functions

    func updateMapStyle(_ style: MLNStyle?) {
        self.navigationVisualization.style = style
//        navigationVisualization.map = style
    }

    func requestUserLocationPermissionsIfNeeded() {
        self.userLocationStore.startMonitoringPermissions()
    }

    func updateCameraPosition(to cameraPosition: MapViewCamera) {
        self.mapStore.camera = cameraPosition
    }

    func didTapOnMap(at _: CLLocationCoordinate2D, and point: CGPoint) {
        let specificFeatures = self.mapViewController.mapView.visibleFeatures(at: point, styleLayerIdentifiers: MapLayerIdentifier.tapLayers)
        self.mapViewStore.didTapOnMap(containing: specificFeatures)

        let routesFeatures = self.mapViewController
            .mapView
            .visibleFeatures(
                at: point,
                styleLayerIdentifiers: MapLayerIdentifier.routeLayers
            )

        if let tappedRouteFeature = routesFeatures.first(where: { $0.attribute(forKey: "id") != nil }),
           let routeId = tappedRouteFeature.attribute(forKey: "id") as? Int {
            self.navigationVisualization.selectRoute(with: routeId)
        }
    }

    func handleLongPress(at location: CLLocationCoordinate2D, and _: CGPoint) {
        if self.mapStore.selectedItem == nil {
            let generatedPOI = ResolvedItem(
                id: UUID().uuidString,
                title: "Dropped Pin",
                subtitle: nil,
                type: .hudhud,
                coordinate: location,
                color: .systemRed
            )
            self.mapStore.select(generatedPOI)
        }
    }

    func congestionSource(for level: String, segments: [CongestionSegment], id: Int) -> ShapeSource {
        ShapeSource(identifier: "congestion-\(level)-\(id)") {
            segments.filter { $0.level == level }.map { segment in
                MLNPolylineFeature(coordinates: segment.geometry)
            }
        }
    }

    func congestionLayer(for level: String, source: ShapeSource, id: Int) -> LineStyleLayer {
        LineStyleLayer(identifier: "congestion-line-\(level)-\(id)", source: source)
            .lineCap(.round)
            .lineJoin(.round)
            .lineColor(self.colorForCongestionLevel(level))
            .lineWidth(
                interpolatedBy: .zoomLevel,
                curveType: .linear,
                parameters: NSExpression(forConstantValue: 1.5),
                stops: NSExpression(forConstantValue: [
                    14: 6,
                    16: 7,
                    18: 9,
                    20: 16
                ])
            )
    }

    private func listenForNavigationVisualizationEvents() {
        self.navigationVisualization
            .$routes
            .sink { [weak self] routes in
                guard let self else { return }
                self.routes = routes
            }
            .store(in: &self.cancellables)

        self.navigationVisualization
            .$selectedRoute
            .sink { [weak self] selctedRoute in
                guard let self else { return }
                self.selectedRoute = selctedRoute
                self.onSelectedRouteChanged(selctedRoute)
            }
            .store(in: &self.cancellables)
    }

    private func onSelectedRouteChanged(_ selectedRoute: Route?) {
        if let selectedRoute {
            let camera = MapViewCamera.boundingBox(selectedRoute.bbox.mlnCoordinateBounds)
            self.mapStore.camera = camera
        }
    }

    private func colorForCongestionLevel(_ level: String) -> UIColor {
        switch level {
        case "unknown": return .gray
        case "low": return .green
        case "moderate": return .yellow
        case "heavy": return .orange
        case "severe": return .red
        default: return .blue
        }
    }
}

extension MapLayerIdentifier {
    nonisolated static let tapLayers: Set<String> = [
        Self.restaurants,
        Self.shops,
        Self.simpleCircles,
        Self.streetView,
        Self.customPOI
    ]

    nonisolated static let routeLayers: Set<String> = [
        Self.routeLineInner,
        Self.routeLineCasing
    ]
}

// MARK: - MapViewContainer

struct MapViewContainer: View {

    // MARK: Properties

    @Binding var isSheetShown: Bool

    @ObservedObject var mapStore: MapStore

    @State private var didFocusOnUser = false

    @State private var store: MapViewContainerStore

    // MARK: Computed Properties

    var locationLabel: String {
        guard let userLocation = store.lastLocation else {
            return "No location - authed as \(self.store.locationPermissionStatus)"
        }

        return "±\(Int(userLocation.horizontalAccuracy))m accuracy"
    }

    @State private var errorMessage: String? {
        didSet {
            Task {
                try await Task.sleep(nanoseconds: 8 * NSEC_PER_SEC)
                self.errorMessage = nil
            }
        }
    }

    // MARK: Lifecycle

    init(
        store: MapViewContainerStore,
        mapStore: MapStore,
        isSheetShown: Binding<Bool>
    ) {
        self._store = State(initialValue: store)
        self.mapStore = mapStore
        self._isSheetShown = isSheetShown
    }

    // MARK: Content

    var body: some View {
        NavigationStack {
            MapView(
                makeViewController: MLNMapViewController(),
                styleURL: self.store.styleURL,
                camera: Binding(get: {
                    self.store.mapStore.camera
                }, set: { newvalue in
                    self.store.updateCameraPosition(to: newvalue)
                }),
                locationManager: self.store.locationManager
            ) {
                let routePoints = self.store.navigationVisualization.routePoints
                let selectedRoute = self.store.navigationVisualization.selectedRoute
                let alternativeRoutes = self.store.navigationVisualization.alternativeRoutes

                if self.store.navigationVisualization.isNavigating {
                    // the state is .navigating
                } else {
                    // render alternative routes first
                    for route in alternativeRoutes {
                        let polylineSource = ShapeSource(identifier: "alternative-route-\(route.id)") {
                            MLNPolylineFeature(coordinates: route.geometry.clLocationCoordinate2Ds)
                        }

                        LineStyleLayer(
                            identifier: "alternative-route-casing-\(route.id)",
                            source: polylineSource
                        )
                        .lineCap(.round)
                        .lineJoin(.round)
                        .lineColor(.lightGray)
                        .lineWidth(interpolatedBy: .zoomLevel,
                                   curveType: .linear,
                                   parameters: NSExpression(forConstantValue: 1.5),
                                   stops: NSExpression(forConstantValue: [18: 10, 20: 20]))

                        LineStyleLayer(
                            identifier: "alternative-route-inner-\(route.id)",
                            source: polylineSource
                        )
                        .lineCap(.round)
                        .lineJoin(.round)
                        .lineColor(.systemBlue.withAlphaComponent(0.5))
                        .lineWidth(interpolatedBy: .zoomLevel,
                                   curveType: .linear,
                                   parameters: NSExpression(forConstantValue: 1.5),
                                   stops: NSExpression(forConstantValue: [18: 8, 20: 14]))

                        CircleStyleLayer(
                            identifier: MapLayerIdentifier.simpleCirclesRoute + "\(route.id)",
                            source: routePoints
                        )
                        .radius(16)
                        .color(.systemRed)
                        .strokeWidth(2)
                        .strokeColor(.white)
                        SymbolStyleLayer(
                            identifier: MapLayerIdentifier.simpleSymbolsRoute + "\(route.id)",
                            source: routePoints
                        )
                        .iconImage(UIImage(systemSymbol: .mappin).withRenderingMode(.alwaysTemplate))
                        .iconColor(.white)
                    }

                    // Render the selected route
                    if let selectedRoute {
                        let polylineSource = ShapeSource(identifier: "selected-route") {
                            MLNPolylineFeature(coordinates: selectedRoute.geometry.clLocationCoordinate2Ds)
                        }

                        LineStyleLayer(
                            identifier: "selected-route-casing",
                            source: polylineSource
                        )
                        .lineCap(.round)
                        .lineJoin(.round)
                        .lineColor(.white)
                        .lineWidth(
                            interpolatedBy: .zoomLevel,
                            curveType: .linear,
                            parameters: NSExpression(forConstantValue: 1.5),
                            stops: NSExpression(forConstantValue: [
                                18: 14,
                                20: 26
                            ]
                            )
                        )

                        LineStyleLayer(
                            identifier: "selected-route-inner",
                            source: polylineSource
                        )
                        .lineCap(.round)
                        .lineJoin(.round)
                        .lineColor(.systemBlue)
                        .lineWidth(interpolatedBy: .zoomLevel,
                                   curveType: .linear,
                                   parameters: NSExpression(forConstantValue: 1.5),
                                   stops: NSExpression(forConstantValue: [18: 11, 20: 18]))
                    }

                    let allRoutes: [Route] = alternativeRoutes + [selectedRoute].compactMap { $0 } // make selected on top

                    for routeModel in allRoutes {
                        let segments = routeModel.extractCongestionSegments()
                        let congestionLevels = ["moderate", "heavy", "severe"]

                        for level in congestionLevels {
                            let source = self.store.congestionSource(for: level, segments: segments, id: routeModel.id)
                            self.store.congestionLayer(for: level, source: source, id: routeModel.id)
                        }
                    }

                    if self.store.debugStore.customMapSymbols == true, self.store.mapStore.displayableItems.isEmpty, self.store.mapStore.isSFSymbolLayerPresent(), self.store.mapStore.shouldShowCustomSymbols {
                        SymbolStyleLayer(identifier: MapLayerIdentifier.customPOI, source: MLNSource(identifier: "hpoi"), sourceLayerIdentifier: "public.poi")
                            .iconImage(mappings: SFSymbolSpriteSheet.spriteMapping, default: SFSymbolSpriteSheet.defaultMapPin)
                            .iconAllowsOverlap(false)
                            .text(featurePropertyNamed: "name")
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
                            .textFontNames(["IBMPlexSansArabic-Regular"])
                    }

                    let pointSource = self.store.mapStore.points

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

                    SymbolStyleLayer(identifier: MapLayerIdentifier.simpleCircles, source: pointSource.makeMGLSource())
                        .iconImage(mappings: SFSymbolSpriteSheet.spriteMapping, default: SFSymbolSpriteSheet.defaultMapPin)
                        .iconAllowsOverlap(false)
                        .text(featurePropertyNamed: "name")
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
                        .predicate(NSPredicate(format: "cluster != YES"))

                    // shows the selected pin
                    CircleStyleLayer(
                        identifier: MapLayerIdentifier.selectedCircle,
                        source: self.store.mapStore.selectedPoint
                    )
                    .radius(24)
                    .color(UIColor(self.store.mapStore.selectedItem?.color ?? Color(.systemRed)))
                    .strokeWidth(2)
                    .strokeColor(.white)
                    .predicate(NSPredicate(format: "cluster != YES"))
                    SymbolStyleLayer(
                        identifier: MapLayerIdentifier.selectedCircleIcon,
                        source: self.store.mapStore.selectedPoint
                    )
                    .iconImage(UIImage(systemSymbol: self.store.mapStore.selectedItem?.symbol ?? .mappin, withConfiguration: UIImage.SymbolConfiguration(pointSize: 24)).withRenderingMode(.alwaysTemplate))
                    .iconColor(.white)
                    .predicate(NSPredicate(format: "cluster != YES"))
                }
            }
            .onStyleLoaded { style in
                self.store.updateMapStyle(style)
            }
            .onTapMapGesture(count: 1, onTapChanged: { context in
                self.store.didTapOnMap(at: context.coordinate, and: context.point)
            })
            .onLongPressMapGesture(onPressChanged: { mapGesture in
                self.store.handleLongPress(at: mapGesture.coordinate, and: mapGesture.point)
            })
            .unsafeMapViewControllerModifier { mapViewController in
                //  mapViewController.mapView.locationManager = nil
                mapViewController.mapView.compassViewMargins.y = 50
            }
            .mapControls {
                CompassView()
                LogoView()
                    .hidden(true)
                AttributionButton()
                    .hidden(true)
            }
            .gesture(
                DragGesture()
                    .onChanged { _ in
                        if self.store.mapStore.trackingState != .none {
                            self.store.mapStore.trackingState = .none
                        }
                    }
            )
            .onAppear {
                self.store.requestUserLocationPermissionsIfNeeded()
                guard !self.didFocusOnUser else { return }
                self.didFocusOnUser = true
                self.store.updateCameraPosition(to: .trackUserLocation())
                // without this line the user location puck does not appear on start up
            }
//                .onChange(of: self.searchViewStore.routingStore.navigatingRoute) { newValue in
//                    if let route = newValue {
//                        do {
//
//                            try self.searchViewStore.routingStore.ferrostarCore.startNavigation(route: route)
//                            self.isSheetShown = false
//                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
//                                self.mapStore.camera = .automotiveNavigation()
//                            }
//                        } catch {
//                            Logger.routing.error("Routing Error: \(error)")
//                        }
//                    } else {
//                        self.stopNavigation()
//                        if let simulated = searchViewStore.routingStore.ferrostarCore.locationProvider as? SimulatedLocationProvider {
//                            simulated.stopUpdating()
//                        }
//                    }
//                }
            .task {
                guard !self.didFocusOnUser else { return }
                self.didFocusOnUser = true
            }
            .edgesIgnoringSafeArea(.all)
        }
    }

    // MARK: Functions

    // MARK: - Internal

//    @MainActor
//    func stopNavigation() {
//        self.searchViewStore.endTrip()
//        self.isSheetShown = true
//
//        if let coordinates = self.searchViewStore.routingStore.ferrostarCore.locationProvider.lastLocation?.coordinates {
//            // pitch is broken upstream again, so we use pitchRange for a split second to force to 0.
//            self.mapStore.camera = .center(coordinates.clLocationCoordinate2D, zoom: 14, pitch: 0, pitchRange: .fixed(0))
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                self.mapStore.camera = .center(coordinates.clLocationCoordinate2D, zoom: 14, pitch: 0, pitchRange: .free)
//            }
//        }
//        self.routingStore.clearRoutes()
//    }

}

// #Preview {
//    @Previewable let mapStore: MapStore = .storeSetUpForPreviewing
//    @Previewable let searchStore: SearchViewStore = .storeSetUpForPreviewing
//    MapViewContainer(
//        store: <#T##MapViewContainerStore#>,
//        isSheetShown: .constant(true)
//    )
// }

//
// DynamicallyOrientingNavigationView(
//    makeViewController: MLNMapViewController(),
//    styleURL: self.mapStore.mapStyleUrl(),
//    camera: self.$mapStore.camera,
//    locationProviding: self.searchViewStore.routingStore.ferrostarCore.locationProvider,
//    navigationState: self.searchViewStore.routingStore.ferrostarCore.state,
//    showZoom: false
// ) {
//    // onTapExit
//    self.stopNavigation()
//
// } makeMapContent: {
//    let routePoints = self.searchViewStore.routingStore.routePoints
//    // Separate the selected route from alternatives
//    let selectedRoute = self.searchViewStore.routingStore.routes.first(where: { $0.isSelected })
//    let alternativeRoutes = self.searchViewStore.routingStore.routes.filter { !$0.isSelected }
//
//    if self.searchViewStore.routingStore.ferrostarCore.isNavigating {
//        // The state is .navigating
//    } else {
//        // Render alternative routes first
//        for routeModel in alternativeRoutes {
//            let polylineSource = ShapeSource(identifier: "alternative-route-\(routeModel.id)") {
//                MLNPolylineFeature(coordinates: routeModel.route.geometry.clLocationCoordinate2Ds)
//            }
//
//            LineStyleLayer(
//                identifier: "alternative-route-casing-\(routeModel.id)",
//                source: polylineSource
//            )
//            .lineCap(.round)
//            .lineJoin(.round)
//            .lineColor(.lightGray)
//            .lineWidth(interpolatedBy: .zoomLevel,
//                       curveType: .linear,
//                       parameters: NSExpression(forConstantValue: 1.5),
//                       stops: NSExpression(forConstantValue: [18: 10, 20: 20]))
//
//            LineStyleLayer(
//                identifier: "alternative-route-inner-\(routeModel.id)",
//                source: polylineSource
//            )
//            .lineCap(.round)
//            .lineJoin(.round)
//            .lineColor(.systemBlue.withAlphaComponent(0.5))
//            .lineWidth(interpolatedBy: .zoomLevel,
//                       curveType: .linear,
//                       parameters: NSExpression(forConstantValue: 1.5),
//                       stops: NSExpression(forConstantValue: [18: 8, 20: 14]))
//
//            CircleStyleLayer(
//                identifier: MapLayerIdentifier.simpleCirclesRoute + "\(routeModel.id)",
//                source: routePoints
//            )
//            .radius(16)
//            .color(.systemRed)
//            .strokeWidth(2)
//            .strokeColor(.white)
//            SymbolStyleLayer(
//                identifier: MapLayerIdentifier.simpleSymbolsRoute + "\(routeModel.id)",
//                source: routePoints
//            )
//            .iconImage(UIImage(systemSymbol: .mappin).withRenderingMode(.alwaysTemplate))
//            .iconColor(.white)
//        }
//
//        // Render the selected route
//        if let selectedRoute {
//            let polylineSource = ShapeSource(identifier: "selected-route") {
//                MLNPolylineFeature(coordinates: selectedRoute.route.geometry.clLocationCoordinate2Ds)
//            }
//
//            LineStyleLayer(
//                identifier: "selected-route-casing",
//                source: polylineSource
//            )
//            .lineCap(.round)
//            .lineJoin(.round)
//            .lineColor(.white)
//            .lineWidth(interpolatedBy: .zoomLevel,
//                       curveType: .linear,
//                       parameters: NSExpression(forConstantValue: 1.5),
//                       stops: NSExpression(forConstantValue: [18: 14, 20: 26]))
//
//            LineStyleLayer(
//                identifier: "selected-route-inner",
//                source: polylineSource
//            )
//            .lineCap(.round)
//            .lineJoin(.round)
//            .lineColor(.systemBlue)
//            .lineWidth(interpolatedBy: .zoomLevel,
//                       curveType: .linear,
//                       parameters: NSExpression(forConstantValue: 1.5),
//                       stops: NSExpression(forConstantValue: [18: 11, 20: 18]))
//        }
//
//        let allRoutes: [RouteModel] = alternativeRoutes + [selectedRoute].compactMap { $0 }
//        for routeModel in allRoutes {
//            let segments = routeModel.route.extractCongestionSegments()
//            let congestionLevels = ["moderate", "heavy", "severe"]
//
//            for level in congestionLevels {
//                let source = self.congestionSource(for: level, segments: segments, id: routeModel.id)
//                self.congestionLayer(for: level, source: source, id: routeModel.id)
//            }
//        }
//
//        if self.debugStore.customMapSymbols == true, self.mapStore.displayableItems.isEmpty, self.mapStore.isSFSymbolLayerPresent(), self.mapStore.shouldShowCustomSymbols {
//            SymbolStyleLayer(identifier: MapLayerIdentifier.customPOI, source: MLNSource(identifier: "hpoi"), sourceLayerIdentifier: "public.poi")
//                .iconImage(mappings: SFSymbolSpriteSheet.spriteMapping, default: SFSymbolSpriteSheet.defaultMapPin)
//                .iconAllowsOverlap(false)
//                .text(featurePropertyNamed: "name")
//                .textFontSize(11)
//                .maximumTextWidth(8.0)
//                .textHaloColor(UIColor.white)
//                .textHaloWidth(1.0)
//                .textHaloBlur(0.5)
//                .textAnchor("top")
//                .textColor(expression: SFSymbolSpriteSheet.colorExpression)
//                .textOffset(CGVector(dx: 0, dy: 1.2))
//                .minimumZoomLevel(13.0)
//                .maximumZoomLevel(22.0)
//                .textFontNames(["IBMPlexSansArabic-Regular"])
//        }

//        let pointSource = self.mapStore.points
//
//        // shows the clustered pins
//        CircleStyleLayer(identifier: MapLayerIdentifier.simpleCirclesClustered, source: pointSource)
//            .radius(16)
//            .color(.systemRed)
//            .strokeWidth(2)
//            .strokeColor(.white)
//            .predicate(NSPredicate(format: "cluster == YES"))
//        SymbolStyleLayer(identifier: MapLayerIdentifier.simpleSymbolsClustered, source: pointSource)
//            .textColor(.white)
//            .text(expression: NSExpression(format: "CAST(point_count, 'NSString')"))
//            .predicate(NSPredicate(format: "cluster == YES"))
//
//        // shows the unclustered pins
//
//        SymbolStyleLayer(identifier: MapLayerIdentifier.simpleCircles, source: pointSource.makeMGLSource())
//            .iconImage(mappings: SFSymbolSpriteSheet.spriteMapping, default: SFSymbolSpriteSheet.defaultMapPin)
//            .iconAllowsOverlap(false)
//            .text(featurePropertyNamed: "name")
//            .textFontSize(11)
//            .maximumTextWidth(8.0)
//            .textHaloColor(UIColor.white)
//            .textHaloWidth(1.0)
//            .textHaloBlur(0.5)
//            .textAnchor("top")
//            .textColor(expression: SFSymbolSpriteSheet.colorExpression)
//            .textOffset(CGVector(dx: 0, dy: 1.2))
//            .minimumZoomLevel(13.0)
//            .maximumZoomLevel(22.0)
//            .predicate(NSPredicate(format: "cluster != YES"))

// shows the selected pin
//        CircleStyleLayer(
//            identifier: MapLayerIdentifier.selectedCircle,
//            source: self.mapStore.selectedPoint
//        )
//        .radius(24)
//        .color(UIColor(self.mapStore.selectedItem?.color ?? Color(.systemRed)))
//        .strokeWidth(2)
//        .strokeColor(.white)
//        .predicate(NSPredicate(format: "cluster != YES"))
//        SymbolStyleLayer(
//            identifier: MapLayerIdentifier.selectedCircleIcon,
//            source: self.mapStore.selectedPoint
//        )
//        .iconImage(UIImage(systemSymbol: self.mapStore.selectedItem?.symbol ?? .mappin, withConfiguration: UIImage.SymbolConfiguration(pointSize: 24)).withRenderingMode(.alwaysTemplate))
//        .iconColor(.white)
//        .predicate(NSPredicate(format: "cluster != YES"))
//    }
// } mapViewModifiers: { content, isNavigating in
//    if isNavigating {
//        content
//    } else {
//        content
//            .unsafeMapViewControllerModifier { mapViewController in
//                mapViewController.mapView.locationManager = nil
//                mapViewController.mapView.compassViewMargins.y = 50
//            }
//            .onTapMapGesture(on: MapLayerIdentifier.tapLayers) { _, features in
//                self.mapViewStore.didTapOnMap(containing: features)
//            }
//            .expandClustersOnTapping(clusteredLayers: [ClusterLayer(layerIdentifier: MapLayerIdentifier.simpleCirclesClustered, sourceIdentifier: MapSourceIdentifier.points)])
//            .cameraModifierDisabled(self.searchViewStore.routingStore.navigatingRoute != nil)
//            .onStyleLoaded { style in
//                self.mapStore.mapStyle = style
//                self.mapStore.shouldShowCustomSymbols = self.mapStore.isSFSymbolLayerPresent()
//            }
//            .onLongPressMapGesture(onPressChanged: { mapGesture in
//                if self.searchViewStore.mapStore.selectedItem == nil {
//                    let generatedPOI = ResolvedItem(id: UUID().uuidString, title: "Dropped Pin", subtitle: nil, type: .hudhud, coordinate: mapGesture.coordinate, color: .systemRed)
//                    self.searchViewStore.mapStore.select(generatedPOI)
//                }
//            })
//            .mapControls {
//                CompassView()
//                LogoView()
//                    .hidden(true)
//                AttributionButton()
//                    .hidden(true)
//            }
//    }
// }
// .innerGrid(
//    topCenter: {
//        if let errorMessage {
//            NavigationUIBanner(severity: .error) {
//                Text(errorMessage)
//            }
//            .onTapGesture {
//                self.errorMessage = nil
//            }
//        }
//    },
//    bottomTrailing: {
//        VStack {
//            if self.searchViewStore.routingStore.ferrostarCore.isNavigating == true {
//                Text(self.locationLabel)
//                    .font(.caption)
//                    .padding(.all, 8)
//                    .foregroundColor(.white)
//                    .background(
//                        Color.black.opacity(0.7).clipShape(
//                            .buttonBorder, style: FillStyle()
//                        ))
//            }
//        }
//    }
// )
//

// }

import Combine
import CoreLocation
import FerrostarCore
import FerrostarCoreFFI
import MapLibre

public typealias UserLocation = FerrostarCoreFFI.UserLocation

// MARK: - LocationManagerProxy

public class LocationManagerProxy: NSObject, MLNLocationManager, ObservableObject {

    // MARK: Properties

    public weak var delegate: (any MLNLocationManagerDelegate)?

    public var headingOrientation: CLDeviceOrientation = .portrait

    private let locationProvider: LocationProviding
    private var cancellable: AnyCancellable?

    // MARK: Computed Properties

    public var lastLocation: CLLocationCoordinate2D? {
        self.locationProvider.lastLocation?.coordinates.clLocationCoordinate2D
    }

    public var lastCLHeading: CLHeading? {
        guard let heading = locationProvider.lastHeading else { return nil }
        let clHeading = CLHeading()
        clHeading.setValue(Double(heading.trueHeading), forKey: "trueHeading")
        clHeading.setValue(Double(heading.accuracy), forKey: "headingAccuracy")
        clHeading.setValue(heading.timestamp, forKey: "timestamp")
        return clHeading
    }

    public var authorizationStatus: CLAuthorizationStatus {
        self.locationProvider.authorizationStatus
    }

    // MARK: Lifecycle

    public init(locationProvider: LocationProviding) {
        self.locationProvider = locationProvider
        super.init()
        self.setupLocationUpdates()
    }

    // MARK: Functions

    public func requestAlwaysAuthorization() {
        // No-op, handled by LocationProviding implementation
    }

    public func requestWhenInUseAuthorization() {
        // No-op, handled by LocationProviding implementation
    }

    public func dismissHeadingCalibrationDisplay() {
        // No-op
    }

    public func startUpdatingLocation() {
        self.locationProvider.startUpdating()
    }

    public func stopUpdatingLocation() {
        self.locationProvider.stopUpdating()
    }

    public func startUpdatingHeading() {
        // Handled by startUpdating() in LocationProviding
    }

    public func stopUpdatingHeading() {
        // Handled by stopUpdating() in LocationProviding
    }

    func updateLocation(_ location: UserLocation) {
        let clLocation = CLLocation(
            coordinate: location.coordinates.clLocationCoordinate2D,
            altitude: 0,
            horizontalAccuracy: location.horizontalAccuracy,
            verticalAccuracy: -1,
            course: Double(location.courseOverGround?.degrees ?? 0),
            speed: location.speed?.value ?? -1,
            timestamp: location.timestamp
        )

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.delegate?.locationManager(self, didUpdate: [clLocation])
        }
    }

    private func setupLocationUpdates() {
        if let simulatedProvider = locationProvider as? SimulatedLocationProvider {
            self.cancellable = simulatedProvider.$lastLocation
                .compactMap { $0 }
                .sink { [weak self] location in
                    self?.updateLocation(location)
                }
        } else {
            // rela location provider
        }
    }
}
