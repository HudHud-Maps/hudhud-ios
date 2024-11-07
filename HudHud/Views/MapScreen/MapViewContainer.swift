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

struct MapViewContainer<SheetContentView: View>: View {

    // MARK: Properties

    @Bindable var mapStore: MapStore
    @ObservedObject var debugStore: DebugStore
    @ObservedObject var searchViewStore: SearchViewStore
    @ObservedObject var userLocationStore: UserLocationStore
    @ObservedObject var routingStore: RoutingStore
    let streetViewStore: StreetViewStore
    let mapViewStore: MapViewStore
    let routesPlanMapDrawer: RoutesPlanMapDrawer
    let navigationStore: NavigationStore

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
        navigationStore: NavigationStore,
        debugStore: DebugStore,
        searchViewStore: SearchViewStore,
        userLocationStore: UserLocationStore,
        mapViewStore: MapViewStore,
        routingStore: RoutingStore,
        sheetStore: SheetStore,
        streetViewStore: StreetViewStore,
        routesPlanMapDrawer: RoutesPlanMapDrawer,
        @ViewBuilder sheetToView: @escaping (SheetType) -> SheetContentView
    ) {
        self.mapStore = mapStore
        self.navigationStore = navigationStore
        self.debugStore = debugStore
        self.searchViewStore = searchViewStore
        self.userLocationStore = userLocationStore
        self.mapViewStore = mapViewStore
        self.streetViewStore = streetViewStore
        self.routingStore = routingStore
        self.sheetStore = sheetStore
        self.routesPlanMapDrawer = routesPlanMapDrawer
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
                locationManager: self.navigationStore.locationManager,
                styleURL: self.mapStore.mapStyleUrl(),
                camera: self.$mapStore.camera,
                isNavigating: self.navigationStore.state.status == .navigating,
                isMuted: self.navigationStore.state.isMuted,
                showZoom: false,
                onTapMute: { self.navigationStore.execute(.toggleMute) },
                makeMapContent: makeMapContent,
                mapViewModifiers: makeMapViewModifiers
            )
            .innerGrid(
                topCenter: { ErrorBannerView(errorMessage: self.$errorMessage) },
                bottomTrailing: { LocationInfoView(isNavigating: self.navigationStore.state.isNavigating, label: locationLabel) },
                bottomLeading: {
                    if self.navigationStore.state.isNavigating {
                        SpeedView(speed: self.speed, speedLimit: speedLimit)
                    }
                }
            )
            .withNavigationOverlay(.instructions) {
                if let navigationState = navigationStore.navigationState, navigationState.isNavigating {
                    LegacyInstructionsView(navigationState: navigationState)
                }
            }
            .withNavigationOverlay(.tripProgress) {
                if let navigationState = navigationStore.navigationState,
                   let progress = navigationState.currentProgress,
                   navigationState.isNavigating {
                    ActiveTripInfoView(tripProgress: progress) { actions in
                        switch actions {
                        case .exitNavigation:
                            stopNavigation()
                        default:
                            break
                        }
                    }
                }
            }
            .gesture(trackingStateGesture)
            .onAppear(perform: handleOnAppear)
            .onChange(of: self.routingStore.selectedRoute) { oldValue, newValue in
                handlePotentialRouteChange(oldValue, newValue)
            }
            .onReceive(AppEvents.publisher, perform: { navigationEvent in
                switch navigationEvent {
                case .startNavigation:
                    self.navigationStore.execute(.startNavigation)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        self.mapStore.camera = .automotiveNavigation()
                    }
                    self.sheetStore.isShown.value = false
                case .stopNavigation:
                    self.navigationStore.execute(.stopNavigation)
                }
            })

//            .onChange(of: self.routingStore.navigatingRoute) { oldValue, newValue in
//                handleNavigatingRouteChange(oldValue, newValue)
//            }
//            .onChange(of: self.routingStore.ferrostarCore.state?.tripState) { oldValue, newValue in
//                handleTripStateChange(oldValue, newValue)
//            }
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
//        return self.routingStore.ferrostarCore.annotation?.speedLimit
        .kilometersPerHour(44)
    }
}

// MARK: - Map Content

private extension MapViewContainer {

    func makeMapContent() -> [StyleLayerDefinition] {
        guard !self.navigationStore.state.isNavigating else { return [] }

        var layers: [StyleLayerDefinition] = []

        print("shot routes \(self.routesPlanMapDrawer.routes)")
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

//        if let routePolyline = navigationState?.routePolyline {
//            RouteStyleLayer(polyline: routePolyline,
//                            identifier: "route-polyline",
//                            style: TravelledRouteStyle())
//        }
//
//        if let remainingRoutePolyline = navigationState?.remainingRoutePolyline {
//            RouteStyleLayer(polyline: remainingRoutePolyline,
//                            identifier: "remaining-route-polyline")
//        }
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

    func handleTripStateChange(_ oldValue: TripState?, _ newValue: TripState?) {
        if let newValue {
            switch newValue {
            case .idle:
                UIApplication.shared.isIdleTimerDisabled = false
            case .navigating:
                UIApplication.shared.isIdleTimerDisabled = true
            case .complete:
                UIApplication.shared.isIdleTimerDisabled = false
            }
        }

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
        self.searchViewStore.endTrip()
        self.sheetStore.popToRoot()
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

public extension Waypoint {
    init(coordinate: CLLocationCoordinate2D, kind: WaypointKind = .via) {
        self.init(coordinate: GeographicCoordinate(lat: coordinate.latitude, lng: coordinate.longitude), kind: kind)
    }

    var cLCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: self.coordinate.lat, longitude: self.coordinate.lng)
    }
}

public extension Route {
    var duration: TimeInterval {
        // add together all routeStep durations
        return self.steps.reduce(0) { $0 + $1.duration }
    }
}

// MARK: - Route + Identifiable

extension Route: @retroactive Identifiable {
    public var id: Int {
        return self.hashValue
    }

}

public extension BoundingBox {
    var mlnCoordinateBounds: MLNCoordinateBounds {
        return MLNCoordinateBounds(sw: self.sw.clLocationCoordinate2D, ne: self.ne.clLocationCoordinate2D)
    }
}

public extension [GeographicCoordinate] {
    var clLocationCoordinate2Ds: [CLLocationCoordinate2D] {
        return self.map(\.clLocationCoordinate2D)
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

// MARK: - ActiveTripInfoViewAction

enum ActiveTripInfoViewAction {
    case exitNavigation
    case switchToRoutePreviewMode
    case openNavigationSettings
}

// MARK: - ActiveTripInfoView

struct ActiveTripInfoView: View {

    // MARK: Properties

    let tripProgress: TripProgress
    let onAction: (ActiveTripInfoViewAction) -> Void

    @State var isExpanded: Bool = false

    // MARK: Content

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.Colors.General._02Grey.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 12)

            ProgressView(
                tripProgress: self.tripProgress,
                isExpanded: self.isExpanded,
                onAction: self.onAction
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white)
                .shadow(
                    color: .black.opacity(0.05),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - ActiveTripInfoView.ProgressView

extension ActiveTripInfoView {

    struct ProgressView: View {

        // MARK: Properties

        let distanceFormatter: Formatter
        let estimatedArrivalFormatter: Date.FormatStyle
        let durationFormatter: DateComponentsFormatter
        let isExpanded: Bool
        let fromDate: Date = .init()

        private let tripProgress: TripProgress
        private let onAction: (ActiveTripInfoViewAction) -> Void

        // MARK: Lifecycle

        init(tripProgress: TripProgress, isExpanded: Bool, onAction: @escaping (ActiveTripInfoViewAction) -> Void) {
            self.tripProgress = tripProgress
            self.onAction = onAction
            self.isExpanded = isExpanded
            self.distanceFormatter = DefaultFormatters.distanceFormatter
            self.estimatedArrivalFormatter = DefaultFormatters.estimatedArrivalFormat
            self.durationFormatter = DefaultFormatters.durationFormat
        }

        // MARK: Content

        var body: some View {
            HStack {
                VStack(alignment: .leading) {
                    if let formattedDuration = durationFormatter.string(from: tripProgress.durationRemaining) {
                        Text(formattedDuration)
                            .hudhudFont(.title2)
                            .fontWeight(.semibold)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                            .multilineTextAlignment(.center)
                    }

                    HStack(alignment: .center, spacing: 4) {
                        Text(self.estimatedArrivalFormatter.format(self.tripProgress.estimatedArrival(from: self.fromDate)))
                            .hudhudFont(.callout)
                            .fontWeight(.semibold)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                            .foregroundStyle(Color.Colors.General._02Grey)
                            .multilineTextAlignment(.center)

                        Text("·")
                            .hudhudFont(.callout)
                            .fontWeight(.semibold)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                            .foregroundStyle(Color.Colors.General._02Grey)
                            .multilineTextAlignment(.center)

                        Text(self.distanceFormatter.string(for: self.tripProgress.distanceRemaining) ?? "")
                            .hudhudFont(.callout)
                            .fontWeight(.semibold)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                            .foregroundStyle(Color.Colors.General._02Grey)
                            .multilineTextAlignment(.center)
                    }
                }

                Spacer()

                NavigationControls(onAction: self.onAction)
            }
        }
    }
}

// MARK: - NavigationControls

struct NavigationControls: View {

    // MARK: Properties

    let onAction: (ActiveTripInfoViewAction) -> Void

    // MARK: Content

    var body: some View {
        HStack(spacing: 16) {
            RoutePreviewButton {
                self.onAction(.switchToRoutePreviewMode)
            }

            FinishButton {
                self.onAction(.exitNavigation)
            }
        }
    }
}

// MARK: - RoutePreviewButton

private struct RoutePreviewButton: View {

    // MARK: Properties

    let onTap: () -> Void

    // MARK: Content

    var body: some View {
        Button(action: {
            self.onTap()
        }) {
            Image(.routePreviewIcon)
                .frame(width: 56, height: 56)
                .background(Color.Colors.General._03LightGrey)
                .clipShape(Circle())
        }
        .accessibilityLabel("Preview Route")
    }
}

// MARK: - FinishButton

private struct FinishButton: View {

    // MARK: Properties

    let action: () -> Void

    // MARK: Content

    var body: some View {
        Button(action: {
            self.action()
        }) {
            Text("Finish")
                .hudhudFont(.callout)
                .fontWeight(.semibold)
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(height: 56)
                .background(Color.Colors.General._03LightGrey)
                .clipShape(Capsule())
        }
    }
}

#Preview(body: {
    ActiveTripInfoView(tripProgress: .init(distanceToNextManeuver: 100, distanceRemaining: 1000, durationRemaining: 1500)) { _ in
    }
})
