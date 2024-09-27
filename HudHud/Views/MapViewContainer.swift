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
    @ObservedObject var mapViewStore: MapViewStore
    var sheetSize: CGSize

    @State private var didFocusOnUser = false

    // MARK: Computed Properties

    var locationLabel: String {
        guard let userLocation = searchViewStore.routingStore.ferrostarCore.locationProvider.lastLocation else {
            return
                "No location - authed as \(self.searchViewStore.routingStore.ferrostarCore.locationProvider.authorizationStatus)"
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
        mapStore: MapStore,
        debugStore: DebugStore,
        searchViewStore: SearchViewStore,
        userLocationStore: UserLocationStore,
        mapViewStore: MapViewStore,
        sheetSize: CGSize
    ) {
        self.mapStore = mapStore
        self.debugStore = debugStore
        self.searchViewStore = searchViewStore
        self.sheetSize = sheetSize
        self.userLocationStore = userLocationStore
        self.mapViewStore = mapViewStore

        // boot up ferrostar
    }

    // MARK: Content

    var body: some View {
        NavigationStack {
            DynamicallyOrientingNavigationView(styleURL: self.mapStore.mapStyleUrl(), camera: self.$mapStore.camera, navigationState: self.searchViewStore.routingStore.ferrostarCore.state) {
                // onTapExit
                self.stopNavigation()
            } makeMapContent: {
                if self.searchViewStore.routingStore.ferrostarCore.isNavigating {
                    // The state is .navigating
                    // You can perform your actions here
                } else {
                    if let route = self.searchViewStore.routingStore.potentialRoute {
                        let polylineSource = ShapeSource(identifier: MapSourceIdentifier.pedestrianPolyline) {
                            MLNPolylineFeature(coordinates: route.geometry.clLocationCoordinate2Ds)
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

                        let routePoints = self.searchViewStore.routingStore.routePoints

                        CircleStyleLayer(identifier: MapLayerIdentifier.simpleCirclesRoute, source: routePoints)
                            .radius(16)
                            .color(.systemRed)
                            .strokeWidth(2)
                            .strokeColor(.white)
                        SymbolStyleLayer(identifier: MapLayerIdentifier.simpleSymbolsRoute, source: routePoints)
                            .iconImage(UIImage(systemSymbol: .mappin).withRenderingMode(.alwaysTemplate))
                            .iconColor(.white)
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

            } mapViewModifiersWhenNotNavigating: { content in
                AnyView(
                    content

                            .unsafeMapViewControllerModifier { mapViewController in

                                mapViewController.mapView.locationManager = nil // if we don't do this, the user location puck is not shown at start up...
                            }

                            .onTapMapGesture(on: MapLayerIdentifier.tapLayers) { _, features in
                                /*
                                 if self.searchViewStore.routingStore.navigationProgress == .feedback {
                                     self.searchViewStore.endTrip()
                                     return
                                 }
                                  */
                                self.mapViewStore.didTapOnMap(containing: features)
                            }
                            .expandClustersOnTapping(clusteredLayers: [ClusterLayer(layerIdentifier: MapLayerIdentifier.simpleCirclesClustered, sourceIdentifier: MapSourceIdentifier.points)])
                            //   .cameraModifierDisabled(self.searchViewStore.routingStore.navigatingRoute != nil)
                            .onStyleLoaded { style in
                                self.mapStore.mapStyle = style
                                self.mapStore.shouldShowCustomSymbols = self.mapStore.isSFSymbolLayerPresent()
                            }
                            .onLongPressMapGesture(onPressChanged: { mapGesture in
                                if self.searchViewStore.mapStore.selectedItem == nil {
                                    let selectedItem = ResolvedItem(id: UUID().uuidString, title: "Dropped Pin", subtitle: "", type: .hudhud, coordinate: mapGesture.coordinate, color: .systemRed)
                                    self.searchViewStore.mapStore.selectedItem = selectedItem
                                    self.mapViewStore.selectedDetent = .third
                                }
                            })
                            .safeAreaPadding(.bottom, self.mapStore.searchShown ? self.sheetPaddingSize() : 0)
                            .onChange(of: self.searchViewStore.routingStore.potentialRoute) { _, newRoute in
                                if let route = newRoute {
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
                                self.mapStore.camera = .trackUserLocation() // without this line the user location puck does not appear on start up
                            }
                )
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
            .onChange(of: self.searchViewStore.routingStore.navigatingRoute) { newValue in
                if let route = newValue {
                    do {
                        if let simulated = searchViewStore.routingStore.ferrostarCore.locationProvider as? SimulatedLocationProvider {
                            // This configures the simulator to the desired route.
                            // The ferrostarCore.startNavigation will still start the location
                            // provider/simulator.
                            try simulated.setSimulatedRoute(route, resampleDistance: 5)
                            print("DemoApp: setting route to be simulated")
                        }

                        // Starts the navigation state machine.
                        // It's worth having a look through the parameters,
                        // as most of the configuration happens here.

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            print("Cam update...")
                            self.mapStore.camera = .trackUserLocationWithCourse(zoom: 15, pitch: 45, pitchRange: .fixed(45))
                        }
                        try self.searchViewStore.routingStore.ferrostarCore.startNavigation(route: route)
                        self.mapStore.searchShown = false
                    } catch {
                        Logger.routing.error("Routing Error: \(error)")
                    }
                } else {
                    self.stopNavigation()
                    self.mapStore.searchShown = true
                }
            }
            .task {
                guard self.didFocusOnUser else { return }
                self.didFocusOnUser = true
                await self.mapStore.focusOnUser()
            }
        }
    }

    // MARK: Functions

    // MARK: - Internal

    func sheetPaddingSize() -> Double {
        if self.sheetSize.height > 80 {
            return 80
        } else {
            return self.sheetSize.height
        }
    }

    @MainActor
    func stopNavigation() {
        print("Stopping navigation")
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

}

#Preview {
    @Previewable let mapStore: MapStore = .storeSetUpForPreviewing
    @Previewable let searchStore: SearchViewStore = .storeSetUpForPreviewing
    MapViewContainer(mapStore: mapStore, debugStore: DebugStore(), searchViewStore: searchStore, userLocationStore: .storeSetUpForPreviewing, mapViewStore: .storeSetUpForPreviewing, sheetSize: CGSize(width: 80, height: 80))
}
