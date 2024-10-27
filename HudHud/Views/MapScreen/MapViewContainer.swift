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

struct MapViewContainer<SheetContentView: View>: View {

    // MARK: Properties

    @Bindable var mapStore: MapStore
    @ObservedObject var debugStore: DebugStore
    @ObservedObject var searchViewStore: SearchViewStore
    @ObservedObject var userLocationStore: UserLocationStore
    @ObservedObject var routingStore: RoutingStore
    let streetViewStore: StreetViewStore
    let mapViewStore: MapViewStore

    @ViewBuilder let sheetToView: (SheetType) -> SheetContentView

    @State private var safeAreaInsets = UIEdgeInsets()
    @State private var didFocusOnUser = false
    private var sheetStore: SheetStore

    // MARK: Computed Properties

    @State private var errorMessage: String? {
        didSet { scheduleErrorDismissal() }
    }

    // MARK: Lifecycle

    init(
        mapStore: MapStore,
        debugStore: DebugStore,
        searchViewStore: SearchViewStore,
        userLocationStore: UserLocationStore,
        mapViewStore: MapViewStore,
        routingStore: RoutingStore,
        sheetStore: SheetStore,
        streetViewStore: StreetViewStore,
        @ViewBuilder sheetToView: @escaping (SheetType) -> SheetContentView
    ) {
        self.mapStore = mapStore
        self.debugStore = debugStore
        self.searchViewStore = searchViewStore
        self.userLocationStore = userLocationStore
        self.mapViewStore = mapViewStore
        self.streetViewStore = streetViewStore
        self.routingStore = routingStore
        self.sheetStore = sheetStore
        self.sheetToView = sheetToView
    }

    // MARK: Content

    var body: some View {
        return NavigationStack {
            DynamicallyOrientingNavigationView(
                makeViewController: MapViewController(
                    sheetStore: self.sheetStore,
                    styleURL: self.mapStore.mapStyleUrl(),
                    sheetToView: self.sheetToView
                ),
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

extension MapViewContainer {
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

// MARK: - Event Handlers

// TODO: - Move it to its own store
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
                try self.routingStore.ferrostarCore.startNavigation(route: route)
                if let simulated = routingStore.ferrostarCore.simulatedLocationProvider {
                    try configureLocationSimulator(simulated, with: route)
                }

                self.sheetStore.isShown.value = false

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
        self.sheetStore.show(.pointOfInterest(generatedPOI))
    }

    func configureMapViewController(_ mapViewController: MapViewController) {
        mapViewController.mapView.locationManager = LocationManagerProxy(locationProvider: self.routingStore.ferrostarCore.locationProvider)

        mapViewController.mapView.compassViewMargins.y = 50
    }
}

// MARK: - Helper Functions

// TODO: - Move it to its own store
private extension MapViewContainer {
    @MainActor
    func stopNavigation() {
        self.searchViewStore.endTrip()
        self.sheetStore.isShown.value = true

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
        simulated.stopUpdating() // to privent camera jumps when we simulate location at high speeds
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

extension FerrostarCore {
    var simulatedLocationProvider: SimulatedLocationProvider? {
        self.locationProvider as? SimulatedLocationProvider
    }
}
