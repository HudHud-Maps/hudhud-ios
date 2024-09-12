//
//  MapStore.swift
//  HudHud
//
//  Created by Patrick Kladek on 23.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import Combine
import CoreLocation
import Foundation
import MapboxCoreNavigation
import MapboxDirections
import MapboxNavigation
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import OSLog
import SwiftUI

// MARK: - MapStore

@MainActor
final class MapStore: ObservableObject {

    // MARK: Nested Types

    enum TrackingState {
        case none
        case locateOnce
        case keepTracking
    }

    enum CameraUpdateState {
        case route(RoutingService.RouteCalculationResult?)
        case selectedItem(ResolvedItem)
        case userLocation(CLLocationCoordinate2D)
        case mapItems
        case defaultLocation
    }

    // MARK: Properties

    let motionViewModel: MotionViewModel
    var mapStyle: MLNStyle?

    @AppStorage("mapStyleLayer") var mapStyleLayer: HudHudMapLayer?
    @Published var shouldShowCustomSymbols = false
    @Published var camera: MapViewCamera = .center(.riyadh, zoom: 10, pitch: 0, pitchRange: .fixed(0))
    @Published var searchShown: Bool = true
    @Published var trackingState: TrackingState = .none

    var hudhudStreetView = HudhudStreetView()
    @Published var streetViewScene: StreetViewScene?
    @Published var nearestStreetViewScene: StreetViewScene?
    @Published var fullScreenStreetView: Bool = false
    var cachedScenes = [Int: StreetViewScene]()
    var mapView: NavigationMapView?
    let userLocationStore: UserLocationStore

    @Published private(set) var selectedItem: ResolvedItem?

    @Published var displayableItems: [DisplayableRow] = []

    private let hudhudResolver = HudHudPOI()
    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Computed Properties

    var mapItems: [ResolvedItem] {
        let allItems = Set(self.displayableItems)

        if let selectedItem {
            let items = allItems.union([DisplayableRow.resolvedItem(selectedItem)])
            return items.compactMap(\.resolvedItem)
        }

        return self.displayableItems.compactMap(\.resolvedItem)
    }

    var points: ShapeSource {
        return ShapeSource(identifier: MapSourceIdentifier.points, options: [.clustered: true, .clusterRadius: 44]) {
            self.mapItems.compactMap { item in
                return MLNPointFeature(coordinate: item.coordinate) { feature in
                    feature.attributes["poi_id"] = item.id
                    feature.attributes["ios_category_icon_name"] = item.symbol.rawValue
                    feature.attributes["ios_category_icon_color"] = item.systemColor.rawValue
                    feature.attributes["name"] = item.title
                }
            }
        }
    }

    var selectedPoint: ShapeSource {
        ShapeSource(identifier: MapSourceIdentifier.selectedPoint, options: [.clustered: false]) {
            if let selectedItem {
                let feature = MLNPointFeature(coordinate: selectedItem.coordinate)
                feature.attributes["poi_id"] = selectedItem.id
                feature
            }
        }
    }

    // MARK: Lifecycle

    init(camera: MapViewCamera = MapViewCamera.center(.riyadh, zoom: 10), searchShown: Bool = true, motionViewModel: MotionViewModel, userLocationStore: UserLocationStore) {
        self.camera = camera
        self.searchShown = searchShown
        self.motionViewModel = motionViewModel
        self.userLocationStore = userLocationStore
        bindLayersVisability()
        bindCameraToUserLocationForFirstTime()
    }

    // MARK: Functions

    // MARK: - Internal

    // MARK: poi items functions

    func replaceItemsAndFocusCamera(on items: [DisplayableRow]) {
        self.displayableItems = items
        self.updateCamera(state: .mapItems)
    }

    func clearListAndSelect(_ item: ResolvedItem) {
        self.selectedItem = item
        self.displayableItems = [DisplayableRow.resolvedItem(item)]
    }

    func unselectItem() {
        self.selectedItem = nil
    }

    func select(_ item: ResolvedItem, shouldFocusCamera: Bool = false) {
        self.selectedItem = item
        if shouldFocusCamera {
            self.updateCamera(state: .selectedItem(item))
        }
    }

    func clearItems() {
        self.selectedItem = nil
        self.displayableItems = []
    }

    func getCameraPitch() -> Double {
        if case let .centered(
            onCoordinate: _,
            zoom: _,
            pitch: pitch,
            pitchRange: _,
            direction: _
        ) = camera.state {
            return pitch
        }
        return 0
    }

    func mapStyleUrl() -> URL {
        guard let styleUrl = self.mapStyleLayer?.styleUrl else {
            return URL(string: "https://static.maptoolkit.net/styles/hudhud/hudhud-default-v1.json?api_key=hudhud")! // swiftlint:disable:this force_unwrapping
        }
        return styleUrl
    }

    func focusOnUser() async {
        guard let location = await self.userLocationStore.location()?.coordinate else { return }
        withAnimation {
            self.updateCamera(state: .userLocation(location))
        }
    }

    func updateCurrentMapStyle(mapLayers: [HudHudMapLayer]) {
        // On first launch we use the first one returned and set it as default.
        if let mapLayer = self.mapStyleLayer {
            if !mapLayers.contains(mapLayer) {
                // The currently used style is not included in the map layers from the server
                if let firstLayer = mapLayers.first {
                    self.mapStyleLayer = firstLayer
                } else {
                    // Handle the case where mapLayers is empty if needed
                    Logger().error("No available map layers from the server.")
                }
            }
        } else {
            // Set the first map style as default
            if let firstLayer = mapLayers.first {
                self.mapStyleLayer = firstLayer
            } else {
                // Handle the case where no map layers are returned from the server
                Logger().error("No available map layers from the server.")
            }
        }
    }

    func resolve(_ item: ResolvedItem) async {
        let itemIfAvailable = self.displayableItems
            .first { $0.id == item.id }
        if itemIfAvailable == nil {
            self.displayableItems.append(.resolvedItem(item))
        }
        self.select(item, shouldFocusCamera: true)
        guard let detailedItem = try? await hudhudResolver.lookup(id: item.id, baseURL: DebugStore().baseURL),
              // we make sure that this item is still selected
              detailedItem.id == self.selectedItem?.id,
              let index = self.displayableItems.firstIndex(where: { $0.id == detailedItem.id }) else { return }
        var detailedItemUpdate = detailedItem
        detailedItemUpdate.systemColor = item.systemColor
        detailedItemUpdate.symbol = item.symbol
        self.displayableItems[index] = .resolvedItem(detailedItemUpdate)
        self.selectedItem = detailedItemUpdate
    }

    func updateCamera(state: CameraUpdateState) {
        switch state {
        // show the whole route on the map
        case let .route(result):
            if let routes = result?.routes {
                if let route = routes.first,
                   let coordinates = route.coordinates,
                   coordinates.hasElements,
                   let boundingBox = self.generateMLNCoordinateBounds(from: coordinates) {
                    self.camera = MapViewCamera.boundingBox(boundingBox,
                                                            edgePadding: UIEdgeInsets(top: 40, left: 40, bottom: 60, right: 40))
                }
                return
            }
        case let .selectedItem(selectedItem):
            self.camera = .center(selectedItem.coordinate, zoom: self.camera.zoom ?? 15)
        case let .userLocation(userLocation):
            self.camera = MapViewCamera.center(userLocation, zoom: 14)
        case .mapItems:
            self.handleMapItems()
        default:
            self.camera = MapViewCamera.center(.riyadh, zoom: 16)
        }
    }

    func switchToNextTrackingAction() async {
        switch self.trackingState {
        case .none:
            await self.focusOnUser()
            self.trackingState = .locateOnce
            Logger.mapInteraction.log("None action required")
        case .locateOnce:
            self.trackingState = .keepTracking
            Logger.mapInteraction.log("locate me Once")
        case .keepTracking:
            self.trackingState = .none
            Logger.mapInteraction.log("keep Tracking of user location")
        }
    }

    func isSFSymbolLayerPresent() -> Bool {
        return self.mapStyle?.layers.contains(where: { $0.identifier == MapLayerIdentifier.restaurants || $0.identifier == MapLayerIdentifier.shops }) ?? false
    }

    func zoomToStreetViewLocation() {
        guard let lat = streetViewScene?.lat else { return }
        guard let lon = streetViewScene?.lon else { return }
        self.camera = .center(CLLocationCoordinate2D(latitude: lat, longitude: lon),
                              zoom: 15, pitch: 0, pitchRange: .fixed(0))
    }

    func loadNearestStreetView(minLon: Double, minLat: Double, maxLon: Double, maxLat: Double) async {
        do {
            self.nearestStreetViewScene = try await self.hudhudStreetView.getStreetViewSceneBBox(box: [minLon, minLat, maxLon, maxLat])
        } catch {
            self.nearestStreetViewScene = nil
            Logger.streetViewScene.error("Loading StreetViewScene failed \(error)")
        }
    }

    func loadStreetViewScene(id: Int) async {
        if let item = self.cachedScenes[id] {
            self.streetViewScene = item
            return
        }

        do {
            if let streetViewScene = try await hudhudStreetView.getStreetViewScene(id: id, baseURL: DebugStore().baseURL) {
                Logger.streetView.log("SVD: streetViewScene0: \(self.streetViewScene.debugDescription)")
                self.streetViewScene = streetViewScene
                self.cachedScenes[streetViewScene.id] = streetViewScene
            }
        } catch {
            Logger.streetViewScene.error("Loading StreetViewScene failed \(error)")
        }
    }

    func preloadStreetViewScene(id: Int) async {
        if self.cachedScenes[id] != nil {
            return
        }

        do {
            if let streetViewScene = try await hudhudStreetView.getStreetViewScene(id: id, baseURL: DebugStore().baseURL) {
                self.cachedScenes[streetViewScene.id] = streetViewScene
            }
        } catch {
            Logger.streetViewScene.error("Loading StreetViewScene failed \(error)")
        }
    }

}

// MARK: - Previewable

extension MapStore: Previewable {

    static let storeSetUpForPreviewing = MapStore(motionViewModel: .storeSetUpForPreviewing, userLocationStore: .storeSetUpForPreviewing)
}

// MARK: - Private

private extension MapStore {

    func bindLayersVisability() {
        self.$displayableItems
            .map(\.isEmpty)
            .removeDuplicates()
            .sink { [weak self] isEmpty in
                self?.mapStyle?.layers.forEach { layer in
                    if layer.identifier.hasPrefix(MapLayerIdentifier.hudhudPOIPrefix) {
                        layer.isVisible = isEmpty
                    }
                }
            }
            .store(in: &self.subscriptions)
    }

    func bindCameraToUserLocationForFirstTime() {
        self.userLocationStore.$permissionStatus
            .filter(\.isEnabled) // only go through if the location permission is enabled
            .first() // only call the closure once
            .sink { [weak self] _ in
                Task {
                    await self?.focusOnUser()
                }
            }
            .store(in: &self.subscriptions)
    }

    func generateMLNCoordinateBounds(from coordinates: [CLLocationCoordinate2D]) -> MLNCoordinateBounds? {
        guard !coordinates.isEmpty else {
            return nil
        }

        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude

        for coordinate in coordinates {
            if coordinate.latitude < minLat {
                minLat = coordinate.latitude
            }
            if coordinate.latitude > maxLat {
                maxLat = coordinate.latitude
            }
            if coordinate.longitude < minLon {
                minLon = coordinate.longitude
            }
            if coordinate.longitude > maxLon {
                maxLon = coordinate.longitude
            }
        }

        let southWest = CLLocationCoordinate2D(latitude: minLat, longitude: minLon)
        let northEast = CLLocationCoordinate2D(latitude: maxLat, longitude: maxLon)

        return MLNCoordinateBounds(sw: southWest, ne: northEast)
    }

    func handleMapItems() {
        switch self.mapItems.count {
        case 0:
            break // no items, do nothing
        case 1:
            // if there is only one item ...center around this location
            if let item = mapItems.first {
                self.camera = .center(item.coordinate, zoom: 16)
            }
        case 2...:
            let coordinates = self.mapItems.map(\.coordinate)
            if let camera = CameraState.boundingBox(from: coordinates) {
                self.camera = camera
            }
        default:
            break // should never occur
        }
    }

    func getCameraCoordinate() -> CLLocationCoordinate2D {
        if case let .centered(
            onCoordinate: onCoordinate,
            zoom: _,
            pitch: _,
            pitchRange: _,
            direction: _
        ) = camera.state {
            return onCoordinate
        }
        return CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }

    // check if the there is an item on the Coordinate of the Camera on the map
    func isAnyItemVisible() -> Bool {
        if let bounds = self.mapItems.map(\.coordinate).boundingBox() {
            return bounds.contains(coordinate: self.getCameraCoordinate())
        }
        return false
    }
}

extension [CLLocationCoordinate2D] {

    func boundingBox() -> MLNCoordinateBounds? {
        guard let first = self.first else { return nil }

        var minLat = first.latitude
        var maxLat = first.latitude
        var minLon = first.longitude
        var maxLon = first.longitude

        for coordinate in self {
            if coordinate.latitude < minLat {
                minLat = coordinate.latitude
            }
            if coordinate.latitude > maxLat {
                maxLat = coordinate.latitude
            }
            if coordinate.longitude < minLon {
                minLon = coordinate.longitude
            }
            if coordinate.longitude > maxLon {
                maxLon = coordinate.longitude
            }
        }

        return MLNCoordinateBounds(sw: CLLocationCoordinate2D(latitude: minLat, longitude: minLon),
                                   ne: CLLocationCoordinate2D(latitude: maxLat, longitude: maxLon))
    }
}

extension MLNCoordinateBounds {

    func contains(coordinate: CLLocationCoordinate2D) -> Bool {
        return coordinate.latitude >= self.sw.latitude &&
            coordinate.latitude <= self.ne.latitude &&
            coordinate.longitude >= self.sw.longitude &&
            coordinate.longitude <= self.ne.longitude
    }
}
