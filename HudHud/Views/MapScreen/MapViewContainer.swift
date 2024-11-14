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
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import OSLog
import SwiftUI
import UIKit

// MARK: - MapViewContainer

struct MapViewContainer: View {

    // MARK: Properties

    @Bindable var mapStore: MapStore
    @ObservedObject var debugStore: DebugStore
    @ObservedObject var userLocationStore: UserLocationStore
    @ObservedObject var routingStore: RoutingStore
    let streetViewStore: StreetViewStore
    @State var mapViewStore: MapViewStore
    let routesPlanMapDrawer: RoutesPlanMapDrawer
    let navigationStore: NavigationStore

    @State private var safeAreaInsets = UIEdgeInsets()
    @State private var didFocusOnUser = false
    private var sheetStore: SheetStore

    // MARK: Computed Properties

    @State private var errorMessage: String? {
        didSet { scheduleErrorDismissal() }
    }

    // MARK: Lifecycle

    init(mapStore: MapStore,
         navigationStore: NavigationStore,
         debugStore: DebugStore,
         userLocationStore: UserLocationStore,
         routingStore: RoutingStore,
         sheetStore: SheetStore,
         streetViewStore: StreetViewStore,
         routesPlanMapDrawer: RoutesPlanMapDrawer) {
        self.mapStore = mapStore
        self.navigationStore = navigationStore
        self.debugStore = debugStore
        self.userLocationStore = userLocationStore
        self.mapViewStore = MapViewStore(mapStore: mapStore, streetViewStore: streetViewStore, sheetStore: sheetStore)
        self.streetViewStore = streetViewStore
        self.routingStore = routingStore
        self.sheetStore = sheetStore
        self.routesPlanMapDrawer = routesPlanMapDrawer
    }

    // MARK: Content

    var body: some View {
        return NavigationStack {
            DynamicallyOrientingNavigationView(makeViewController: MapViewController(sheetStore: self.sheetStore,
                                                                                     styleURL: self.mapStore.mapStyleUrl()),
                                               locationManager: self.navigationStore.locationManager,
                                               styleURL: self.mapStore.mapStyleUrl(),
                                               camera: self.$mapStore.camera,
                                               isNavigating: self.navigationStore.state.status == .navigating,
                                               isMuted: self.navigationStore.state.isMuted,
                                               showZoom: false,
                                               onTapMute: { self.navigationStore.execute(.toggleMute) },
                                               makeMapContent: makeMapContent,
                                               mapViewModifiers: makeMapViewModifiers)
                .withNavigationOverlay(.instructions) {
                    if let navigationState = navigationStore.navigationState, navigationState.isNavigating {
                        LegacyInstructionsView(navigationState: navigationState)
                    }
                }
                .withNavigationOverlay(.tripProgress) {
                    if let progress = navigationStore.state.tripProgress,
                       navigationStore.state.isNavigating {
                        TripInfoContianerView(tripProgress: progress,
                                              navigationAlert: self.navigationStore.state.navigationAlert) { actions in
                            switch actions {
                            case .exitNavigation:
                                stopNavigation()
                            case .switchToRoutePreviewMode:
                                if let selectedRoute = routesPlanMapDrawer.selectedRoute {
                                    self.mapStore.camera = .boundingBox(selectedRoute.bbox.mlnCoordinateBounds)
                                }
                            default:
                                break
                            }
                        }
                    }
                }
                .innerGrid(topCenter: { ErrorBannerView(errorMessage: self.$errorMessage) },
                           bottomTrailing: { LocationInfoView(isNavigating: self.navigationStore.state.isNavigating, label: locationLabel) },
                           bottomLeading: {
                               if self.navigationStore.state.isNavigating {
                                   SpeedView(speed: self.speed, speedLimit: speedLimit)
                               }
                           })
                .gesture(trackingStateGesture)
                .onAppear(perform: handleOnAppear)
                .onChange(of: self.routingStore.selectedRoute) { oldValue, newValue in
                    handlePotentialRouteChange(oldValue, newValue)
                }
                .onReceive(AppEvents.publisher, perform: { navigationEvent in
                    switch navigationEvent {
                    case let .startNavigation(route):
                        self.navigationStore.execute(.startNavigation(route))
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            self.mapStore.camera = .automotiveNavigation()
                        }
                        self.sheetStore.isShown.value = false
                        self.sheetStore.popToRoot()
                    case .stopNavigation:
                        self.navigationStore.execute(.stopNavigation)
                    }
                })
                .onChange(of: self.navigationStore.state) { _, newValue in
                    switch newValue.status {
                    case .idle, .navigating:
                        break
                    case .cancelled, .arrived, .failed:
                        stopNavigation()
                    }
                }

                .task { handleInitialFocus() }
        }
    }
}

extension MapViewContainer {
    private var locationLabel: String {
        guard let location = navigationStore.lastKnownLocation else {
            return "No location - authed as \(self.navigationStore.locationManager.authorizationStatus)"
        }
        return "±\(Int(location.horizontalAccuracy))m accuracy"
    }

    private var speed: Measurement<UnitSpeed>? {
        self.navigationStore.lastKnownLocation?.userLocation.speed.map {
            Measurement(value: $0.value, unit: .metersPerSecond)
        }
    }

    private var speedLimit: Measurement<UnitSpeed>? {
        self.navigationStore.state.speedLimit
    }
}

// MARK: - Map Content

private extension MapViewContainer {

    func makeMapContent() -> [StyleLayerDefinition] {
        guard !self.navigationStore.state.isNavigating else {
            return self.makeNavigationConent()
        }

        var layers: [StyleLayerDefinition] = []

        // Routes
        layers += makeAlternativeRouteLayers()
        if let selectedRoute = self.routesPlanMapDrawer.selectedRoute {
            layers += makeSelectedRouteLayers(for: selectedRoute)
        }

        // Congestion
        layers += makeCongestionLayers(for: self.routesPlanMapDrawer.routes)

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

    func makeNavigationConent() -> [StyleLayerDefinition] {
        guard self.navigationStore.state.isNavigating else { return [] }

        var layers: [StyleLayerDefinition] = []

        if let routePolyline = navigationStore.navigationState?.routePolyline {
            layers += RouteStyleLayer(polyline: routePolyline,
                                      identifier: "route-polyline",
                                      style: TravelledRouteStyle())
                .layers
        }

        if let remainingRoutePolyline = navigationStore.navigationState?.remainingRoutePolyline {
            layers += RouteStyleLayer(polyline: remainingRoutePolyline,
                                      identifier: "remaining-route-polyline").layers
        }

        if let alert = navigationStore.state.navigationAlert {
            layers += [
                SymbolStyleLayer(identifier: MapLayerIdentifier.simpleSymbolsRoute + "horizon",
                                 source: ShapeSource(identifier: "alert") {
                                     MLNPointFeature(coordinate: alert.alertType.coordinate)
                                 })
                                 .iconImage(alert.alertType.mapIcon)
            ]
        }
        return layers
    }

    func makeMapViewModifiers(content: MapView<MapViewController>, isNavigating: Bool) -> MapView<MapViewController> {
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
                   let routeID = feature.attributes["routeId"] as? Int {
                    self.routesPlanMapDrawer.selectRoute(withID: routeID)
                } else {
                    if features.isEmpty, !self.routesPlanMapDrawer.routes.isEmpty { return }
                    self.mapViewStore.didTapOnMap(coordinates: context.coordinate, containing: features)
                }
            }
            .expandClustersOnTapping(clusteredLayers: [
                ClusterLayer(layerIdentifier: MapLayerIdentifier.simpleCirclesClustered,
                             sourceIdentifier: MapSourceIdentifier.points)
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

    @MainActor
    func handleInitialFocus() {
        guard !self.didFocusOnUser else { return }
        self.didFocusOnUser = true
    }

    func handleLongPress(_ gesture: MapGestureContext) {
        guard self.mapStore.selectedItem.value == nil else { return }
        let generatedPOI = ResolvedItem(id: UUID().uuidString,
                                        title: "Dropped Pin",
                                        subtitle: nil,
                                        type: .hudhud,
                                        coordinate: gesture.coordinate,
                                        color: .systemRed)
        self.sheetStore.show(.pointOfInterest(generatedPOI))
    }

    func configureMapViewController(_ mapViewController: MapViewController) {
        mapViewController.mapView.compassViewMargins.y = 50
        if DebugStore().showLocationDiagmosticLogs {
            let diagnostic = LocationServicesDiagnostic(mapView: mapViewController.mapView)
            diagnostic.runDiagnostics()
        }
    }
}

// MARK: - Helper Functions

private extension MapViewContainer {

    @MainActor
    func stopNavigation() {
        self.navigationStore.execute(.stopNavigation)
        self.sheetStore.isShown.value = true

        if let coordinates = navigationStore.lastKnownLocation?.coordinate {
            self.resetCamera(to: coordinates)
        }
        self.routingStore.clearRoutes()
    }

    func resetCamera(to coordinates: CLLocationCoordinate2D) {
        // pitch is broken upstream again, so we use pitchRange for a split second to force to 0.
        self.mapStore.camera = .center(coordinates, zoom: 14, pitch: 0, pitchRange: .fixed(0))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.mapStore.camera = .center(coordinates, zoom: 14, pitch: 0, pitchRange: .free)
        }
    }

    func scheduleErrorDismissal() {
        Task {
            try await Task.sleep(nanoseconds: 8 * NSEC_PER_SEC)
            self.errorMessage = nil
        }
    }

    var shouldShowCustomSymbols: Bool {
        self.debugStore.customMapSymbols == true &&
            self.mapStore.displayableItems.isEmpty &&
            self.mapStore.isSFSymbolLayerPresent() &&
            self.mapStore.shouldShowCustomSymbols
    }
}

private extension MapLayerIdentifier {

    nonisolated static let tapLayers: Set<String> = [
        Self.restaurants,
        Self.shops,
        Self.simpleCircles,
        Self.streetView,
        Self.customPOI,
        Self.poiLevel1
    ]
}
