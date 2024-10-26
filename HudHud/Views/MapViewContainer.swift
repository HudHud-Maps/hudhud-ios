//
//  MapViewContainer.swift
//  HudHud
//
//  Created by Alaa . on 05/08/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import FerrostarCore
import FerrostarCoreFFI
import FerrostarMapLibreUI
import FerrostarSwiftUI
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import OSLog
import SwiftUI

// MARK: - MapViewContainer

struct MapViewContainer: View {

    // MARK: Properties

    // MARK: - Store Properties

    @Bindable var mapStore: MapStore
    @ObservedObject var debugStore: DebugStore
    @ObservedObject var searchViewStore: SearchViewStore
    @ObservedObject var userLocationStore: UserLocationStore
    @ObservedObject var routingStore: RoutingStore
    let streetViewStore: StreetViewStore
    let mapViewStore: MapViewStore

    // MARK: - View State

    @State private var safeAreaInsets = UIEdgeInsets()
    @State private var didFocusOnUser = false
    @Binding private var isSheetShown: Bool

    // MARK: Computed Properties

    @State private var errorMessage: String? {
        didSet { scheduleErrorDismissal() }
    }

    private var locationLabel: String {
        guard let location = searchViewStore.routingStore.ferrostarCore.locationProvider.lastLocation else {
            return "No location - authed as \(self.routingStore.ferrostarCore.locationProvider.authorizationStatus)"
        }
        return "±\(Int(location.horizontalAccuracy))m accuracy"
    }

    private var speed: Measurement<UnitSpeed>? {
        self.routingStore.ferrostarCore.locationProvider.lastLocation?.speed.map {
            Measurement(value: $0.value, unit: .metersPerSecond)
        }
    }

    private var speedLimit: Measurement<UnitSpeed>? {
        try? self.routingStore.ferrostarCore.state?
            .currentAnnotation(as: ValhallaOsrmAnnotation.self)?
            .speedLimit?.measurementValue
    }

    // MARK: Lifecycle

    // MARK: - Initialization

    init(
        mapStore: MapStore,
        debugStore: DebugStore,
        searchViewStore: SearchViewStore,
        userLocationStore: UserLocationStore,
        mapViewStore: MapViewStore,
        routingStore: RoutingStore,
        streetViewStore: StreetViewStore,
        isSheetShown: Binding<Bool>
    ) {
        self.mapStore = mapStore
        self.debugStore = debugStore
        self.searchViewStore = searchViewStore
        self.userLocationStore = userLocationStore
        self.mapViewStore = mapViewStore
        self.streetViewStore = streetViewStore
        self.routingStore = routingStore
        self._isSheetShown = isSheetShown
    }
}

// MARK: - View Body

extension MapViewContainer {
    var body: some View {
        return NavigationStack {
            DynamicallyOrientingNavigationView(
                styleURL: self.mapStore.mapStyleUrl(),
                camera: self.$mapStore.camera,
                locationProviding: self.routingStore.ferrostarCore.locationProvider,
                navigationState: self.routingStore.ferrostarCore.state,
                showZoom: false,
                onTapExit: stopNavigation,
                makeMapContent: makeMapContent,
                mapViewModifiers: makeMapViewModifiers
            )
            .innerGrid(
                topCenter: { ErrorBannerView(errorMessage: self.$errorMessage) },
                bottomTrailing: { LocationInfoView(isNavigating: self.routingStore.ferrostarCore.isNavigating, label: self.locationLabel) },
                bottomLeading: {
                    if self.routingStore.ferrostarCore.isNavigating {
                        SpeedView(speed: self.speed, speedLimit: self.speedLimit)
                    }
                }
            )
            .gesture(trackingStateGesture)
            .onAppear(perform: handleOnAppear)
            .onChange(of: self.routingStore.potentialRoute) { oldValue, newValue in
                handlePotentialRouteChange(oldValue, newValue)
            }
            .onChange(of: self.routingStore.navigatingRoute) { oldValue, newValue in
                handleNavigatingRouteChange(oldValue, newValue)
            }
            .onChange(of: self.routingStore.ferrostarCore.state?.tripState) { oldValue, newValue in
                handleTripStateChange(oldValue, newValue)
            }
            .task { handleInitialFocus() }
        }
    }
}

// MARK: - Map Content

private extension MapViewContainer {

    func makeMapContent() -> [StyleLayerDefinition] {
        guard !self.routingStore.ferrostarCore.isNavigating else { return [] }

        var layers: [StyleLayerDefinition] = []

        // Routes
        layers += makeAlternativeRouteLayers()
        if let selectedRoute = routingStore.selectedRoute {
            layers += makeSelectedRouteLayers(for: selectedRoute)
        }

        // Congestion
        let allRoutes = self.routingStore.alternativeRoutes + [self.routingStore.selectedRoute].compactMap { $0 }
        layers += makeCongestionLayers(for: allRoutes)

        // Custom Symbols
        if shouldShowCustomSymbols {
            layers += makeCustomSymbolLayers()
        }

        // Points
        layers += makePointLayers()

        // Street View
        layers += makeStreetViewLayer()

        return layers
    }

    func makeMapViewModifiers(content: MapView<MLNMapViewController>, isNavigating: Bool) -> MapView<MLNMapViewController> {
        guard !isNavigating else { return content }
        let allRouteIndices = 0 ..< 5 // max possible routes
        let routeLayers = allRouteIndices.flatMap { index in
            [
                MapLayerIdentifier.routeInner(index),
                MapLayerIdentifier.routeCasing(index),
                MapLayerIdentifier.congestion("moderate", index: index),
                MapLayerIdentifier.congestion("heavy", index: index),
                MapLayerIdentifier.congestion("severe", index: index)
            ]
        }

        let tappableLayers = MapLayerIdentifier.tapLayers.union(Set(routeLayers))

        return content
            .unsafeMapViewControllerModifier(configureMapViewController)
            .onTapMapGesture(on: tappableLayers) { context, features in
                if let feature = features.first,
                   let routeId = feature.attributes["routeId"] as? Int,
                   let route = routingStore.alternativeRoutes.first(where: { $0.id == routeId }) {
                    self.routingStore.selectRoute(withId: route.id)
                } else {
                    if features.isEmpty, !self.routingStore.routes.isEmpty { return }
                    self.mapViewStore.didTapOnMap(coordinates: context.coordinate, containing: features)
                }
            }
            .expandClustersOnTapping(clusteredLayers: [
                ClusterLayer(
                    layerIdentifier: MapLayerIdentifier.simpleCirclesClustered,
                    sourceIdentifier: MapSourceIdentifier.points
                )
            ])
            .cameraModifierDisabled(self.routingStore.navigatingRoute != nil)
            .onMapViewPortUpdate { self.mapStore.mapViewPort = $0 }
            .onStyleLoaded { [weak mapStore] in
                mapStore?.mapStyle = $0
                mapStore?.shouldShowCustomSymbols = mapStore?.isSFSymbolLayerPresent() ?? false
            }
            .onLongPressMapGesture(onPressChanged: handleLongPress)
            .mapControls {
                CompassView()
                LogoView().hidden(true)
                AttributionButton().hidden(true)
            }
    }
}

// MARK: - Layer Generators

private extension MapViewContainer {
    @MapViewContentBuilder
    func makeAlternativeRouteLayers() -> [StyleLayerDefinition] {
        self.routingStore.alternativeRoutes.enumerated().flatMap { index, route in

            let feature = MLNPolylineFeature(coordinates: route.geometry.clLocationCoordinate2Ds)
            feature.attributes = ["routeId": route.id]
            let polylineSource = ShapeSource(identifier: "alternative-route-\(route.id)") {
                feature
            }

            let routePoints = self.routingStore.routePoints

            let layers: [StyleLayerDefinition] = [
                LineStyleLayer(
                    identifier: MapLayerIdentifier.routeCasing(index),
                    source: polylineSource
                )
                .lineCap(.round)
                .lineJoin(.round)
                .lineColor(.lightGray)
                .lineWidth(interpolatedBy: .zoomLevel,
                           curveType: .linear,
                           parameters: NSExpression(forConstantValue: 1.5),
                           stops: NSExpression(forConstantValue: [18: 10, 20: 20])),

                LineStyleLayer(
                    identifier: MapLayerIdentifier.routeInner(index),
                    source: polylineSource
                )
                .lineCap(.round)
                .lineJoin(.round)
                .lineColor(.systemBlue.withAlphaComponent(0.5))
                .lineWidth(interpolatedBy: .zoomLevel,
                           curveType: .linear,
                           parameters: NSExpression(forConstantValue: 1.5),
                           stops: NSExpression(forConstantValue: [18: 8, 20: 14])),

                CircleStyleLayer(
                    identifier: MapLayerIdentifier.simpleCirclesRoute + "\(route.id)",
                    source: routePoints
                )
                .radius(16)
                .color(.systemRed)
                .strokeWidth(2)
                .strokeColor(.white),

                SymbolStyleLayer(
                    identifier: MapLayerIdentifier.simpleSymbolsRoute + "\(route.id)",
                    source: routePoints
                )
                .iconImage(UIImage(systemSymbol: .mappin).withRenderingMode(.alwaysTemplate))
                .iconColor(.white)
            ]

            return layers
        }
    }

    @MapViewContentBuilder
    func makeSelectedRouteLayers(for route: Route) -> [StyleLayerDefinition] {
        let polylineSource = ShapeSource(identifier: "selected-route") {
            MLNPolylineFeature(coordinates: route.geometry.clLocationCoordinate2Ds)
        }

        [
            LineStyleLayer(
                identifier: "selected-route-casing",
                source: polylineSource
            )
            .lineCap(.round)
            .lineJoin(.round)
            .lineColor(.white)
            .lineWidth(interpolatedBy: .zoomLevel,
                       curveType: .linear,
                       parameters: NSExpression(forConstantValue: 1.5),
                       stops: NSExpression(forConstantValue: [18: 14, 20: 26])),

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
        ]
    }

    @MapViewContentBuilder
    func makeCongestionLayers(for routes: [Route]) -> [StyleLayerDefinition] {
        let congestionLevels = ["moderate", "heavy", "severe"]
        routes.enumerated().flatMap { index, route in
            let segments = route.extractCongestionSegments()
            return congestionLevels.flatMap { level in
                let source = self.congestionSource(for: level, segments: segments, id: route.id)
                return [self.congestionLayer(for: level, source: source, index: index)]
            }
        }
    }

    @MapViewContentBuilder
    func makeCustomSymbolLayers() -> [StyleLayerDefinition] {
        [
            SymbolStyleLayer(
                identifier: MapLayerIdentifier.customPOI,
                source: MLNSource(identifier: "hpoi"),
                sourceLayerIdentifier: "public.poi"
            )
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
        ]
    }

    @MapViewContentBuilder
    func makePointLayers() -> [StyleLayerDefinition] {
        let pointSource = self.mapStore.points

        [
            // Clustered pins
            CircleStyleLayer(identifier: MapLayerIdentifier.simpleCirclesClustered, source: pointSource)
                .radius(16)
                .color(.systemRed)
                .strokeWidth(2)
                .strokeColor(.white)
                .predicate(NSPredicate(format: "cluster == YES")),

            SymbolStyleLayer(identifier: MapLayerIdentifier.simpleSymbolsClustered, source: pointSource)
                .textColor(.white)
                .text(expression: NSExpression(format: "CAST(point_count, 'NSString')"))
                .predicate(NSPredicate(format: "cluster == YES")),

            // Unclustered pins
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
                .predicate(NSPredicate(format: "cluster != YES")),

            // Selected pin
            CircleStyleLayer(identifier: MapLayerIdentifier.selectedCircle, source: self.mapStore.selectedPoint)
                .radius(24)
                .color(UIColor(self.mapStore.selectedItem.value?.color ?? Color(.systemRed)))
                .strokeWidth(2)
                .strokeColor(.white)
                .predicate(NSPredicate(format: "cluster != YES")),

            SymbolStyleLayer(identifier: MapLayerIdentifier.selectedCircleIcon, source: self.mapStore.selectedPoint)
                .iconImage(UIImage(systemSymbol: self.mapStore.selectedItem.value?.symbol ?? .mappin,
                                   withConfiguration: UIImage.SymbolConfiguration(pointSize: 24))
                        .withRenderingMode(.alwaysTemplate))
                .iconColor(.white)
                .predicate(NSPredicate(format: "cluster != YES"))
        ]
    }

    @MapViewContentBuilder
    func makeStreetViewLayer() -> [StyleLayerDefinition] {
        [
            SymbolStyleLayer(identifier: "street-view-point", source: self.streetViewStore.streetViewSource)
                .iconImage(UIImage(systemSymbol: .cameraCircleFill,
                                   withConfiguration: UIImage.SymbolConfiguration(paletteColors: [.white, .black]))
                        .resize(.square(32)))
                .iconRotation(featurePropertyNamed: "heading")
        ]
    }

    private func congestionSource(for level: String, segments: [CongestionSegment], id: Int) -> ShapeSource {
        ShapeSource(identifier: "congestion-\(level)-\(id)") {
            segments.filter { $0.level == level }.map { segment in
                MLNPolylineFeature(coordinates: segment.geometry)
            }
        }
    }

    private func congestionLayer(for level: String, source: ShapeSource, index: Int) -> LineStyleLayer {
        LineStyleLayer(identifier: MapLayerIdentifier.congestion(level, index: index), source: source)
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

// MARK: - Event Handlers

private extension MapViewContainer {
    var trackingStateGesture: some Gesture {
        DragGesture()
            .onChanged { _ in
                if self.mapStore.trackingState != .none {
                    self.mapStore.trackingState = .none
                }
            }
    }

    func handleOnAppear() {
        self.userLocationStore.startMonitoringPermissions()
        guard !self.didFocusOnUser else { return }
        self.didFocusOnUser = true
        self.mapStore.camera = .trackUserLocation()
    }

    func handlePotentialRouteChange(_: Route?, _ newRoute: Route?) {
        guard let route = newRoute,
              routingStore.navigatingRoute == nil else { return }
        self.mapStore.camera = .boundingBox(route.bbox.mlnCoordinateBounds)
    }

    func handleNavigatingRouteChange(_: Route?, _ newValue: Route?) {
        if let route = newValue {
            do {
                if let simulated = routingStore.ferrostarCore.locationProvider as? SimulatedLocationProvider {
                    try configureLocationSimulator(simulated, with: route)
                }

                try self.routingStore.ferrostarCore.startNavigation(route: route)
                self.isSheetShown = false

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.mapStore.camera = .automotiveNavigation()
                }
            } catch {
                Logger.routing.error("Routing Error: \(error)")
            }
        } else {
            stopNavigation()
            if let simulated = routingStore.ferrostarCore.locationProvider as? SimulatedLocationProvider {
                simulated.stopUpdating()
            }
        }
    }

    func handleTripStateChange(_ oldValue: TripState?, _ newValue: TripState?) {
        guard let oldValue,
              let newValue,
              case .navigating = oldValue,
              newValue == .complete else { return }
        stopNavigation()
    }

    @MainActor
    func handleInitialFocus() {
        guard !self.didFocusOnUser else { return }
        self.didFocusOnUser = true
    }

    func handleLongPress(_ gesture: MapGestureContext) {
        guard self.mapStore.selectedItem.value == nil else { return }
        let generatedPOI = ResolvedItem(
            id: UUID().uuidString,
            title: "Dropped Pin",
            subtitle: nil,
            type: .hudhud,
            coordinate: gesture.coordinate,
            color: .systemRed
        )
        self.mapStore.select(generatedPOI)
    }

    func configureMapViewController(_ mapViewController: MLNMapViewController) {
        mapViewController.mapView.locationManager = LocationManagerProxy(locationProvider: self.routingStore.ferrostarCore.locationProvider)

        mapViewController.mapView.compassViewMargins.y = 50
    }
}

// MARK: - Helper Functions

private extension MapViewContainer {
    @MainActor
    func stopNavigation() {
        self.searchViewStore.endTrip()
        self.isSheetShown = true

        if let coordinates = routingStore.ferrostarCore.locationProvider.lastLocation?.coordinates {
            self.resetCamera(to: coordinates)
        }
        self.routingStore.clearRoutes()
    }

    func resetCamera(to coordinates: GeographicCoordinate) {
        // pitch is broken upstream again, so we use pitchRange for a split second to force to 0.
        self.mapStore.camera = .center(coordinates.clLocationCoordinate2D, zoom: 14, pitch: 0, pitchRange: .fixed(0))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.mapStore.camera = .center(coordinates.clLocationCoordinate2D, zoom: 14, pitch: 0, pitchRange: .free)
        }
    }

    func scheduleErrorDismissal() {
        Task {
            try await Task.sleep(nanoseconds: 8 * NSEC_PER_SEC)
            self.errorMessage = nil
        }
    }

    func configureLocationSimulator(_ simulated: SimulatedLocationProvider, with route: Route) throws {
        try simulated.setSimulatedRoute(route, resampleDistance: 5)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            simulated.startUpdating()
        }
    }

    var shouldShowCustomSymbols: Bool {
        self.debugStore.customMapSymbols == true &&
            self.mapStore.displayableItems.isEmpty &&
            self.mapStore.isSFSymbolLayerPresent() &&
            self.mapStore.shouldShowCustomSymbols
    }
}

// MARK: - ErrorBannerView

private struct ErrorBannerView: View {

    // MARK: Properties

    @Binding var errorMessage: String?

    // MARK: Content

    var body: some View {
        if let errorMessage {
            NavigationUIBanner(severity: .error) {
                Text(errorMessage)
            }
            .onTapGesture { self.errorMessage = nil }
        }
    }
}

// MARK: - LocationInfoView

private struct LocationInfoView: View {

    // MARK: Properties

    let isNavigating: Bool
    let label: String

    // MARK: Content

    var body: some View {
        if self.isNavigating {
            Text(self.label)
                .font(.caption)
                .padding(.all, 8)
                .foregroundColor(.white)
                .background(
                    Color.black.opacity(0.7)
                        .clipShape(.buttonBorder, style: FillStyle())
                )
        }
    }
}

#Preview {
    @Previewable let mapStore: MapStore = .storeSetUpForPreviewing
    @Previewable let searchStore: SearchViewStore = .storeSetUpForPreviewing
    MapViewContainer(mapStore: mapStore, debugStore: DebugStore(), searchViewStore: searchStore, userLocationStore: .storeSetUpForPreviewing, mapViewStore: .storeSetUpForPreviewing, routingStore: .storeSetUpForPreviewing, streetViewStore: .storeSetUpForPreviewing, isSheetShown: .constant(true))
}
