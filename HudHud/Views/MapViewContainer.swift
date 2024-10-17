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

    @State private var didFocusOnUser = false

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

    var body: some View {
        NavigationStack {
            DynamicallyOrientingNavigationView(
                makeViewController: MLNMapViewController(),
                styleURL: self.mapStore.mapStyleUrl(),
                camera: self.$mapStore.camera,
                locationProviding: self.searchViewStore.routingStore.ferrostarCore.locationProvider,
                navigationState: self.searchViewStore.routingStore.ferrostarCore.state,
                showZoom: false
            ) {
                // onTapExit
                self.stopNavigation()

            } makeMapContent: {
                let routePoints = self.searchViewStore.routingStore.routePoints
                // Separate the selected route from alternatives
                let selectedRoute = self.searchViewStore.routingStore.routes.first(where: { $0.isSelected })
                let alternativeRoutes = self.searchViewStore.routingStore.routes.filter { !$0.isSelected }

                if self.searchViewStore.routingStore.ferrostarCore.isNavigating {
                    // The state is .navigating
                } else {
                    // Render alternative routes first
                    for routeModel in alternativeRoutes {
                        let polylineSource = ShapeSource(identifier: "alternative-route-\(routeModel.id)") {
                            MLNPolylineFeature(coordinates: routeModel.route.geometry.clLocationCoordinate2Ds)
                        }

                        LineStyleLayer(
                            identifier: "alternative-route-casing-\(routeModel.id)",
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
                            identifier: "alternative-route-inner-\(routeModel.id)",
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
                            identifier: MapLayerIdentifier.simpleCirclesRoute + "\(routeModel.id)",
                            source: routePoints
                        )
                        .radius(16)
                        .color(.systemRed)
                        .strokeWidth(2)
                        .strokeColor(.white)
                        SymbolStyleLayer(
                            identifier: MapLayerIdentifier.simpleSymbolsRoute + "\(routeModel.id)",
                            source: routePoints
                        )
                        .iconImage(UIImage(systemSymbol: .mappin).withRenderingMode(.alwaysTemplate))
                        .iconColor(.white)
                    }

                    // Render the selected route
                    if let selectedRoute {
                        let polylineSource = ShapeSource(identifier: "selected-route") {
                            MLNPolylineFeature(coordinates: selectedRoute.route.geometry.clLocationCoordinate2Ds)
                        }

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
                                   stops: NSExpression(forConstantValue: [18: 14, 20: 26]))

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

                    let allRoutes: [RouteModel] = alternativeRoutes + [selectedRoute].compactMap { $0 }
                    for routeModel in allRoutes {
                        let segments = routeModel.route.extractCongestionSegments()
                        let congestionLevels = ["moderate", "heavy", "severe"]

                        for level in congestionLevels {
                            let source = self.congestionSource(for: level, segments: segments, id: routeModel.id)
                            self.congestionLayer(for: level, source: source, id: routeModel.id)
                        }
                    }

                    if self.debugStore.customMapSymbols == true, self.mapStore.displayableItems.isEmpty, self.mapStore.isSFSymbolLayerPresent(), self.mapStore.shouldShowCustomSymbols {
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
            } mapViewModifiers: { content, isNavigating in
                if isNavigating {
                    content
                } else {
                    content
                        .unsafeMapViewControllerModifier { mapViewController in
                            mapViewController.mapView.locationManager = nil
                            mapViewController.mapView.compassViewMargins.y = 50
                        }
                        .onTapMapGesture(on: MapLayerIdentifier.tapLayers) { _, features in
                            self.mapViewStore.didTapOnMap(containing: features)
                        }
                        .expandClustersOnTapping(clusteredLayers: [ClusterLayer(layerIdentifier: MapLayerIdentifier.simpleCirclesClustered, sourceIdentifier: MapSourceIdentifier.points)])
                        .cameraModifierDisabled(self.searchViewStore.routingStore.navigatingRoute != nil)
                        .onStyleLoaded { style in
                            self.mapStore.mapStyle = style
                            self.mapStore.shouldShowCustomSymbols = self.mapStore.isSFSymbolLayerPresent()
                        }
                        .onLongPressMapGesture(onPressChanged: { mapGesture in
                            if self.searchViewStore.mapStore.selectedItem == nil {
                                let generatedPOI = ResolvedItem(id: UUID().uuidString, title: "Dropped Pin", subtitle: nil, type: .hudhud, coordinate: mapGesture.coordinate, color: .systemRed)
                                self.searchViewStore.mapStore.select(generatedPOI)
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
            .innerGrid(
                topCenter: {
                    if let errorMessage {
                        NavigationUIBanner(severity: .error) {
                            Text(errorMessage)
                        }
                        .onTapGesture {
                            self.errorMessage = nil
                        }
                    }
                },
                bottomTrailing: {
                    VStack {
                        if self.searchViewStore.routingStore.ferrostarCore.isNavigating == true {
                            Text(self.locationLabel)
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
            )
            .onChange(of: self.searchViewStore.routingStore.potentialRoute) { _, newRoute in
                if let route = newRoute, self.searchViewStore.routingStore.navigatingRoute == nil {
                    let camera = MapViewCamera.boundingBox(route.bbox.mlnCoordinateBounds)
                    self.mapStore.camera = camera
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
            .onAppear {
                self.userLocationStore.startMonitoringPermissions()
                guard !self.didFocusOnUser else { return }
                self.didFocusOnUser = true
                self.mapStore.camera = .trackUserLocation() // without this line the user location puck does not appear on start up
            }
            .onChange(of: self.searchViewStore.routingStore.navigatingRoute) { newValue in
                if let route = newValue {
                    do {
                        if let simulated = searchViewStore.routingStore.ferrostarCore.locationProvider as? SimulatedLocationProvider {
                            // This configures the simulator to the desired route.
                            // The ferrostarCore.startNavigation will still start the location
                            // provider/simulator.
                            try simulated.setSimulatedRoute(route, resampleDistance: 5)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                simulated.startUpdating()
                            }
                        }

                        try self.searchViewStore.routingStore.ferrostarCore.startNavigation(route: route)
                        self.isSheetShown = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            self.mapStore.camera = .automotiveNavigation()
                        }
                    } catch {
                        Logger.routing.error("Routing Error: \(error)")
                    }
                } else {
                    self.stopNavigation()
                    if let simulated = searchViewStore.routingStore.ferrostarCore.locationProvider as? SimulatedLocationProvider {
                        simulated.stopUpdating()
                    }
                }
            }
            .task {
                guard !self.didFocusOnUser else { return }

                self.didFocusOnUser = true
            }
        }
    }

    // MARK: Functions

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
        self.routingStore.clearRoutes()
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

#Preview {
    @Previewable let mapStore: MapStore = .storeSetUpForPreviewing
    @Previewable let searchStore: SearchViewStore = .storeSetUpForPreviewing
    MapViewContainer(
        mapStore: mapStore,
        debugStore: DebugStore(),
        searchViewStore: searchStore,
        userLocationStore: .storeSetUpForPreviewing,
        mapViewStore: .storeSetUpForPreviewing,
        routingStore: .storeSetUpForPreviewing,
        isSheetShown: .constant(true)
    )
}
