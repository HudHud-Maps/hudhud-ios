//
//  MapViewContainer.swift
//  HudHud
//
//  Created by Alaa . on 05/08/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import MapboxCoreNavigation
import MapboxNavigation
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import OSLog
import SwiftLocation
import SwiftUI

struct MapViewContainer: View {
    @ObservedObject var mapStore: MapStore
    @ObservedObject var debugStore: DebugStore
    @ObservedObject var searchViewStore: SearchViewStore
    @State private var showUserLocation: Bool = false
    @State private var didTryToZoomOnUsersLocation = false
    var sheetSize: CGSize

    var mapViewStore: MapViewStore

    var body: some View {
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

            if self.debugStore.customMapSymbols == true, self.mapStore.displayableItems.isEmpty {
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
            if self.mapStore.navigationProgress != .navigating {
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
            }
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
        .onStyleLoaded { style in
            self.mapStore.mapStyle = style
        }
        .onLongPressMapGesture(onPressChanged: { mapGesture in
            if self.searchViewStore.mapStore.selectedItem == nil {
                let selectedItem = ResolvedItem(id: UUID().uuidString, title: "Dropped Pin", subtitle: "", type: .hudhud, coordinate: mapGesture.coordinate, color: .systemRed)
                self.searchViewStore.mapStore.selectedItem = selectedItem
                self.mapStore.selectedDetent = .third
            }
        })
        .backport.safeAreaPadding(.bottom, self.mapStore.searchShown ? self.sheetPaddingSize() : 0)
        .onAppear {
            self.showUserLocation = true
        }
        .onChange(of: self.mapStore.routes) { newRoute in
            if let routeUnwrapped = newRoute {
                if let route = routeUnwrapped.routes.first, let coordinates = route.coordinates, !coordinates.isEmpty {
                    if let camera = CameraState.boundingBox(from: coordinates) {
                        self.mapStore.camera = camera
                    }
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
    }

    // MARK: - Lifecycle

    init(
        mapStore: MapStore,
        debugStore: DebugStore,
        searchViewStore: SearchViewStore,
        sheetSize: CGSize
    ) {
        self.mapStore = mapStore
        self.debugStore = debugStore
        self.searchViewStore = searchViewStore
        self.sheetSize = sheetSize
        self.mapViewStore = MapViewStore(mapStore: mapStore)
    }

    // MARK: - Internal

    func sheetPaddingSize() -> Double {
        if self.sheetSize.height > 80 {
            return 80
        } else {
            return self.sheetSize.height
        }
    }

}

#Preview {
    let mapStore: MapStore = .storeSetUpForPreviewing
    let searchStore: SearchViewStore = .storeSetUpForPreviewing
    return MapViewContainer(mapStore: mapStore, debugStore: DebugStore(), searchViewStore: searchStore, sheetSize: CGSize(size: 80))
}
