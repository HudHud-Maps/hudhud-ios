//
//  HudhudMapView.swift
//  HudHud
//
//  Created by Naif Alrashed on 24/07/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import MapboxCoreNavigation
import MapboxNavigation
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import OSLog
import SwiftUI
import UIKit

struct HudhudMapView: View {

    @ObservedObject var mapStore: MapStore
    @ObservedObject var debugStore: DebugStore
    @ObservedObject var trendingStore: TrendingStore
    @Binding var safeAreaInsets: UIEdgeInsets

    private let mapViewStore: MapViewStore
    let showUserLocation: Bool

    // NOTE: As a workaround until Toursprung prvides us with an endpoint that services this file
    private let styleURL = URL(string: "https://static.maptoolkit.net/styles/hudhud/hudhud-default-v1.json?api_key=hudhud")! // swiftlint:disable:this force_unwrapping

    var body: some View {
        MapView<MapNavigationViewController>(makeViewController: {
            let viewController = MapNavigationViewController(dayStyle: CustomDayStyle(), nightStyle: CustomNightStyle())
            viewController.onViewSafeAreaInsetsDidChange = { insets in
                self.safeAreaInsets = insets
            }
            viewController.showsEndOfRouteFeedback = false // We show our own Feedback
            return viewController
        }(), styleURL: self.styleURL, camera: self.$mapStore.camera) {
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
            .radius(24)
            .color(.systemRed)
            .strokeWidth(2)
            .strokeColor(.white)
            .predicate(NSPredicate(format: "cluster != YES"))
            SymbolStyleLayer(
                identifier: MapLayerIdentifier.selectedCircleIcon,
                source: self.mapStore.selectedPoint
            )
            .iconImage(UIImage(systemSymbol: .mappin).withRenderingMode(.alwaysTemplate))
            .iconColor(.white)
            .predicate(NSPredicate(format: "cluster != YES"))

            SymbolStyleLayer(identifier: MapLayerIdentifier.streetViewSymbols, source: self.mapStore.streetViewSource)
                .iconImage(UIImage.lookAroundPin)
                .iconRotation(featurePropertyNamed: "heading")
        }
        .onTapMapGesture(on: MapLayerIdentifier.tapLayers) { _, features in
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
                    controller.mapView.showsUserLocation = self.showUserLocation && self.mapStore.streetView == .disabled
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
            if self.mapStore.selectedItem == nil {
                let selectedItem = ResolvedItem(id: UUID().uuidString, title: "Dropped Pin", subtitle: "", type: .hudhud, coordinate: mapGesture.coordinate, color: .systemRed)
                self.mapStore.selectedItem = selectedItem
            }
        })
        .mapViewContentInset(UIEdgeInsets(
            top: self.safeAreaInsets.top + 40,
            left: 0,
            bottom: self.bottomPadding,
            right: 0
        ))
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
    }

    private var bottomPadding: CGFloat {
        guard self.mapStore.searchShown else { return 0 }
        return if self.mapStore.path.contains(RoutingService.RouteCalculationResult.self) {
            UIScreen.main.bounds.height / 2
        } else {
            80
        }
    }

    // MARK: - Lifecycle

    init(
        mapStore: MapStore,
        debugStore: DebugStore,
        trendingStore: TrendingStore,
        safeAreaInsets: Binding<UIEdgeInsets>,
        showUserLocation: Bool
    ) {
        self.mapStore = mapStore
        self.debugStore = debugStore
        self.trendingStore = trendingStore
        self._safeAreaInsets = safeAreaInsets
        self.showUserLocation = showUserLocation
        self.mapViewStore = MapViewStore(mapStore: mapStore)
    }

}

#Preview {
    HudhudMapView(mapStore: .storeSetUpForPreviewing, debugStore: DebugStore(), trendingStore: TrendingStore(), safeAreaInsets: .constant(UIEdgeInsets(floatLiteral: 0)), showUserLocation: false)
}
