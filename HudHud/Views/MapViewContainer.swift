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

    @ObservedObject var mapStore: MapStore
    @ObservedObject var debugStore: DebugStore
    @ObservedObject var searchViewStore: SearchViewStore
    @ObservedObject var userLocationStore: UserLocationStore
    let mapViewStore: MapViewStore
    @ObservedObject var routingStore: RoutingStore
    @State var safeAreaInsets = UIEdgeInsets()
    @Binding var isSheetShown: Bool

    // MARK: - State

    @State private var safeAreaInsets = UIEdgeInsets()
    @State private var didFocusOnUser = false
    @State private var errorMessage: String?

    // MARK: Computed Properties

    var locationLabel: String {
        guard let userLocation = searchViewStore.routingStore.ferrostarCore.locationProvider.lastLocation else {
            return "No location - authed as \(self.searchViewStore.routingStore.ferrostarCore.locationProvider.authorizationStatus)"
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

    init(mapStore: MapStore,
         debugStore: DebugStore,
         searchViewStore: SearchViewStore,
         userLocationStore: UserLocationStore,
         mapViewStore: MapViewStore,
         routingStore: RoutingStore,
         isSheetShown: Binding<Bool>) {
        self.mapStore = mapStore
        self.debugStore = debugStore
        self.searchViewStore = searchViewStore
        self.userLocationStore = userLocationStore
        self.mapViewStore = mapViewStore
        self.routingStore = routingStore
        self._isSheetShown = isSheetShown
        // boot up ferrostar
    }

    // MARK: Content

    // MARK: - Body

    var body: some View {
        NavigationStack {
            DynamicallyOrientingNavigationView(
                styleURL: self.mapStore.mapStyleUrl(),
                camera: self.$mapStore.camera,
                navigationState: self.searchViewStore.routingStore.ferrostarCore.state
            ) { _ in
                return nil
            }
            onTapExit: {
                self.stopNavigation()
            }
            makeMapContent: {
                self.createMapContent()
            }
            mapViewModifiers: { content, isNavigating in
                self.applyMapViewModifiers(content: content, isNavigating: isNavigating)
            }
            .innerGrid(
                    topCenter: { ErrorMessageBanner(errorMessage: self.$errorMessage) },
                    bottomTrailing: { LocationLabel(isNavigating: self.searchViewStore.routingStore.ferrostarCore.isNavigating, label: self.locationLabel) }
                )
                .onChange(
                    of: self.searchViewStore.routingStore.routes,
                    perform: self.handleRoutesChange
                )
                .gesture(DragGesture().onChanged(self.handleDragGesture))
                .onAppear(perform: self.handleOnAppear)
                .onChange(
                    of: self.searchViewStore.routingStore.navigatingRoute,
                    perform: self.handleNavigatingRouteChange
                )
                .task(self.handleInitialFocus)
        }
    }

    // MARK: Functions

    func getRouteTapLayers() -> Set<String> {
        let layers = self.searchViewStore.routingStore.routes.flatMap { routeModel in
            [
                "\(MapLayerIdentifier.routeLineCasing)-\(routeModel.id)",
                "\(MapLayerIdentifier.routeLineInner)-\(routeModel.id)",
                "congestion-line-moderate-\(routeModel.id)",
                "congestion-line-heavy-\(routeModel.id)",
                "congestion-line-severe-\(routeModel.id)"
            ]
        }.toSet()
        print("Tap detection layers: \(layers)")
        return layers
    }

    @MainActor
    func stopNavigation() {
        self.searchViewStore.routingStore.ferrostarCore.stopNavigation()
        self.searchViewStore.routingStore.potentialRoute = nil
        self.searchViewStore.routingStore.navigatingRoute = nil

        self.mapStore.searchShown = true

        if let coordinates = self.searchViewStore.routingStore.ferrostarCore.locationProvider.lastLocation?.coordinates {
            // pitch is broken upstream again, so we use pitchRange for a split second to force to 0.
            self.mapStore.camera = .center(coordinates.clLocationCoordinate2D, zoom: 14, pitch: 0, pitchRange: .fixed(0))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.mapStore.camera = .center(coordinates.clLocationCoordinate2D, zoom: 14, pitch: 0, pitchRange: .free)
            }
        }
    }

    // MARK: - Internal

    @MainActor
    func stopNavigation() {
        self.searchViewStore.endTrip()
        self.isSheetShown = true

        if let coordinates = self.searchViewStore.routingStore.ferrostarCore.locationProvider.lastLocation?.coordinates {
            // pitch is broken upstream again, so we use pitchRange for a split second to force to 0.
            self.mapStore.camera = .center(coordinates.clLocationCoordinate2D, zoom: 14, pitch: 0, pitchRange: .fixed(0))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.mapStore.camera = .center(coordinates.clLocationCoordinate2D, zoom: 14, pitch: 0, pitchRange: .free)
            }
        }
    }

    @MapViewContentBuilder
    private func createMapContent() -> [StyleLayerDefinition] {
        if self.searchViewStore.routingStore.ferrostarCore.isNavigating {
            // when the state is .navigating
        } else {
            for routeModel in self.searchViewStore.routingStore.routes {
                let polylineSource = ShapeSource(identifier: "\(MapSourceIdentifier.pedestrianPolyline)-\(routeModel.id)") {
                    MLNPolylineFeature(coordinates: routeModel.route.geometry.clLocationCoordinate2Ds)
                }

                let routePoints = self.searchViewStore.routingStore.routePoints

                // a polyline casing for a stroke effect
                LineStyleLayer(identifier: "\(MapLayerIdentifier.routeLineCasing)-\(routeModel.id)", source: polylineSource)
                    .lineCap(.round)
                    .lineJoin(.round)
                    .lineColor(routeModel.isSelected ? .white : .gray)
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

                // an inner polyline
                LineStyleLayer(identifier: "\(MapLayerIdentifier.routeLineInner)-\(routeModel.id)", source: polylineSource)
                    .lineCap(.round)
                    .lineJoin(.round)
                    .lineColor(routeModel.isSelected ? .systemBlue : .lightGray)
                    .lineWidth(
                        interpolatedBy: .zoomLevel,
                        curveType: .linear,
                        parameters: NSExpression(forConstantValue: 1.5),
                        stops: NSExpression(forConstantValue: [
                            18: 11,
                            20: 18
                        ]
                        )
                    )

                let segments = routeModel.route.extractCongestionSegments()
                let congestionLevels = ["moderate", "heavy", "severe"]

                for level in congestionLevels {
                    let source = self.congestionSource(for: level, segments: segments, id: routeModel.id)
                    self.congestionLayer(for: level, source: source, id: routeModel.id)
                }
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

            // shows the clustered pins
            CircleStyleLayer(
                identifier: MapLayerIdentifier.simpleCirclesClustered,
                source: pointSource
            )
            .radius(16)
            .color(.systemRed)
            .strokeWidth(2)
            .strokeColor(.white)
            .predicate(NSPredicate(format: "cluster == YES"))

            SymbolStyleLayer(
                identifier: MapLayerIdentifier.simpleSymbolsClustered,
                source: pointSource
            )
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
                source: self.mapStore.selectedPoint
            )
            .radius(24)
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
    }

    private func applyMapViewModifiers(
        content: MapView<MLNMapViewController>,
        isNavigating: Bool
    ) -> MapView<MLNMapViewController> {
        if isNavigating {
            content
        } else {
            content
                .unsafeMapViewControllerModifier { mapViewController in
                    mapViewController.mapView.locationManager = nil
                    mapViewController.mapView.compassViewMargins.y = 50
                }
                .onTapMapGesture(on: self.getRouteTapLayers()) { context, features in
                    print("Tap on layers at coordinate: \(context.coordinate.latitude), \(context.coordinate.longitude)")
                    print("Number of features: \(features.count)")

                    self.handleRouteTap(features: features)
                }
                .expandClustersOnTapping(clusteredLayers: [ClusterLayer(layerIdentifier: MapLayerIdentifier.simpleCirclesClustered, sourceIdentifier: MapSourceIdentifier.points)])
                .cameraModifierDisabled(self.searchViewStore.routingStore.navigatingRoute != nil)
                .onStyleLoaded { style in
                    self.mapStore.mapStyle = style
                    self.mapStore.shouldShowCustomSymbols = self.mapStore.isSFSymbolLayerPresent()
                    print("All layers in style:")
                    for layer in style.layers {
                        print(" - \(layer.identifier)")
                    }
                }
                .onLongPressMapGesture(onPressChanged: { mapGesture in
                    if self.searchViewStore.mapStore.selectedItem == nil {
                        let generatedPOI = ResolvedItem(id: UUID().uuidString, title: "Dropped Pin", subtitle: nil, type: .hudhud, coordinate: mapGesture.coordinate, color: .systemRed)
                        self.searchViewStore.mapStore.select(generatedPOI)
                        self.mapViewStore.selectedDetent = .third
                    }
                })
                .mapControls {
                    CompassView()
                    LogoView()
                        .hidden(true)
                    AttributionButton()
                        .hidden(true)
                }
        }
    }

    private func handleRouteTap(features: [MLNFeature]) {
        guard let feature = features.first,
              let layerId = feature.identifier as? String,
              let id = Int(layerId) else {
            return
        }

        self.searchViewStore.routingStore.selectRoute(withId: id)
    }

    private func handleRoutesChange(_ routes: [RouteModel]) {
        guard let firstRoute = routes.first?.route else { return }
        let camera = MapViewCamera.boundingBox(firstRoute.bbox.mlnCoordinateBounds)
        self.mapStore.camera = camera
    }

    private func handleDragGesture(_: DragGesture.Value) {
        if self.mapStore.trackingState != .none {
            self.mapStore.trackingState = .none
        }
    }

    private func handleOnAppear() {
        self.userLocationStore.startMonitoringPermissions()
        self.focusOnUserIfNeeded()
    }

    private func handleNavigatingRouteChange(newValue: Route?) {
        if let route = newValue {
            self.startNavigation(with: route)
        } else {
            self.stopNavigation()
        }
    }

    @Sendable
    private func handleInitialFocus() async {
        guard !self.didFocusOnUser else { return }
        self.didFocusOnUser = true
    }

    private func focusOnUserIfNeeded() {
        guard !self.didFocusOnUser else { return }
        self.didFocusOnUser = true
        self.mapStore.camera = .trackUserLocation()
    }

    private func startNavigation(with route: Route) {
        do {
            if let simulated = searchViewStore.routingStore.ferrostarCore.locationProvider as? SimulatedLocationProvider {
                try simulated.setSimulatedRoute(route, resampleDistance: 5)
            }
            try self.searchViewStore.routingStore.ferrostarCore.startNavigation(route: route)
            self.mapStore.searchShown = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.mapStore.camera = .automotiveNavigation()
            }
        } catch {
            Logger.routing.error("Routing Error: \(error)")
        }
    }

    private func congestionSource(for level: String, segments: [CongestionSegment], id: Int) -> ShapeSource {
        ShapeSource(identifier: "congestion-\(level)-\(id)") {
            segments.filter { $0.level == level }.map { segment in
                MLNPolylineFeature(coordinates: segment.geometry)
            }
        }
    }

    private func congestionLayer(for level: String, source: ShapeSource, id: Int) -> LineStyleLayer {
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

// MARK: - ErrorMessageBanner

private struct ErrorMessageBanner: View {

    // MARK: Properties

    @Binding var errorMessage: String?

    // MARK: Content

    var body: some View {
        if let errorMessage {
            NavigationUIBanner(severity: .error) {
                Text(errorMessage)
            }
            .onTapGesture {
                self.errorMessage = nil
            }
        }
    }
}

// MARK: - LocationLabel

private struct LocationLabel: View {

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
                    Color.black.opacity(0.7).clipShape(
                        .buttonBorder, style: FillStyle()
                    ))
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable let mapStore: MapStore = .storeSetUpForPreviewing
    @Previewable let searchStore: SearchViewStore = .storeSetUpForPreviewing
    MapViewContainer(mapStore: mapStore, debugStore: DebugStore(), searchViewStore: searchStore, userLocationStore: .storeSetUpForPreviewing, mapViewStore: .storeSetUpForPreviewing)
}

extension Array where Element: Hashable {
    @inlinable
    func toSet() -> Set<Element> {
        Set(self)
    }
}
