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
import SwiftUI

struct MapViewContainer: View {

    // MARK: Properties

    @ObservedObject var mapStore: MapStore
    @ObservedObject var debugStore: DebugStore
    @ObservedObject var searchViewStore: SearchViewStore
    @ObservedObject var userLocationStore: UserLocationStore
    @ObservedObject var mapViewStore: MapViewStore
    @State var safeAreaInsets = UIEdgeInsets()
    let mapControlInsets: UIEdgeInsets

    @State private var didFocusOnUser = false

    // MARK: Computed Properties

    private var insets: UIEdgeInsets {
        UIEdgeInsets(
            top: self.safeAreaInsets.top + self.mapControlInsets.top,
            left: self.safeAreaInsets.left + self.mapControlInsets.left,
            bottom: self.safeAreaInsets.bottom + self.mapControlInsets.bottom,
            right: self.safeAreaInsets.right + self.mapControlInsets.right
        )
    }

    // MARK: Lifecycle

    init(
        mapStore: MapStore,
        debugStore: DebugStore,
        searchViewStore: SearchViewStore,
        userLocationStore: UserLocationStore,
        mapViewStore: MapViewStore,
        mapControlInsets: UIEdgeInsets
    ) {
        self.mapStore = mapStore
        self.debugStore = debugStore
        self.searchViewStore = searchViewStore
        self.mapControlInsets = mapControlInsets
        self.userLocationStore = userLocationStore
        self.mapViewStore = mapViewStore
    }

    // MARK: Content

    var body: some View {
        MapView<MapNavigationViewController>(makeViewController: {
            let viewController = MapNavigationViewController(dayStyle: CustomDayStyle(), nightStyle: CustomNightStyle())
            viewController.showsEndOfRouteFeedback = false // We show our own Feedback
            viewController.mapView.compassViewMargins.y = 50
            viewController.onViewSafeAreaInsetsDidChange = { newSafeAreaInsets in
                self.safeAreaInsets = newSafeAreaInsets
            }
            self.mapStore.mapView = viewController.mapView
            return viewController
        }(), styleURL: self.mapStore.mapStyleUrl(), camera: self.$mapStore.camera) {
            // Display preview data as a polyline on the map
            if let mapView = self.mapStore.mapView {
                if let potentialRoutes = self.searchViewStore.routingStore.potentialRoute?.routes {
                    mapView.showRoutes(potentialRoutes)
                } else {
                    mapView.removeRoutes()
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
            if self.searchViewStore.routingStore.navigationProgress != .navigating {
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
        .expandClustersOnTapping(clusteredLayers: [ClusterLayer(layerIdentifier: MapLayerIdentifier.simpleCirclesClustered, sourceIdentifier: MapSourceIdentifier.points)])
        .unsafeMapViewControllerModifier { controller in
            self.searchViewStore.routingStore.assign(to: controller, shouldSimulateRoute: self.debugStore.simulateRide)
        }
        .cameraModifierDisabled(self.searchViewStore.routingStore.navigatingRoute != nil)
        .onStyleLoaded { style in
            self.mapStore.mapStyle = style
            self.mapStore.shouldShowCustomSymbols = self.mapStore.isSFSymbolLayerPresent()
        }
        .onLongPressMapGesture(onPressChanged: { mapGesture in
            if self.searchViewStore.mapStore.selectedItem == nil {
                let generatedPOI = ResolvedItem(id: UUID().uuidString, title: "Dropped Pin", subtitle: nil, type: .hudhud, coordinate: mapGesture.coordinate, color: .systemRed)
                self.searchViewStore.mapStore.select(generatedPOI)
                self.mapViewStore.selectedDetent = .third
            }
        })
        .mapViewContentInset(self.insets)
        .mapControls {
            CompassView()
            LogoView()
                .hidden(true)
            AttributionButton()
                .hidden(true)
        }
        .onChange(of: self.searchViewStore.routingStore.potentialRoute) { _, newRoute in
            if let routeUnwrapped = newRoute,
               let route = routeUnwrapped.routes.first,
               let coordinates = route.coordinates,
               !coordinates.isEmpty,
               let camera = CameraState.boundingBox(from: coordinates) {
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
        .simultaneousGesture(
            self.searchViewStore.routingStore.navigationProgress == .none ?
                TapGesture().onEnded {
                    // Check if there's no potential route and not in navigation progress
                    guard self.searchViewStore.routingStore.potentialRoute?.routes == nil,
                          self.searchViewStore.routingStore.navigationProgress != .navigating,
                          let mapView = self.mapStore.mapView,
                          let gestureRecognizers = mapView.gestureRecognizers else { return }

                    // Loop through the gesture recognizers to find tap location
                    for recognizer in gestureRecognizers {
                        let locationInView = recognizer.location(in: mapView)
                        let features = mapView.visibleFeatures(at: locationInView, styleLayerIdentifiers: MapLayerIdentifier.tapLayers)

                        // Handle map tap if not in feedback mode
                        self.mapViewStore.didTapOnMap(containing: features)
                    }
                } : nil
        )
        .onAppear {
            self.userLocationStore.startMonitoringPermissions()
            guard self.didFocusOnUser else { return }

            self.didFocusOnUser = true
            self.mapStore.focusOnUser()
        }
    }
}

#Preview {
    let mapStore: MapStore = .storeSetUpForPreviewing
    let searchStore: SearchViewStore = .storeSetUpForPreviewing
    return MapViewContainer(mapStore: mapStore, debugStore: DebugStore(), searchViewStore: searchStore, userLocationStore: .storeSetUpForPreviewing, mapViewStore: .storeSetUpForPreviewing, mapControlInsets: UIEdgeInsets(floatLiteral: 0))
}
