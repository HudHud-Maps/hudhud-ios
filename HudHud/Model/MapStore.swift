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
import FerrostarCoreFFI
import Foundation
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import OSLog
import SwiftUI

// MARK: - MapStore

@Observable @MainActor
final class MapStore {

    // MARK: Nested Types

    enum TrackingState {
        case none
        case waitingForLocation
        case locateOnce
        case keepTracking
    }

    enum CameraUpdateState {
        case route(Route?)
        case selectedItem(ResolvedItem)
        case userLocation(CLLocationCoordinate2D)
        case streetViewPoint(CLLocationCoordinate2D)
        case mapItems
        case defaultLocation
    }

    // MARK: Properties

    var mapStyle: MLNStyle?
    var shouldShowCustomSymbols = false
    var mapViewPort: MapViewPort?
    let userLocationStore: UserLocationStore

    private(set) var selectedItem: CurrentValueSubject<ResolvedItem?, Never>

    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Computed Properties

    var displayableItems: [DisplayableRow] = [] {
        didSet {
            self.mapStyle?.layers.forEach { layer in
                if layer.identifier.hasPrefix(MapLayerIdentifier.hudhudPOIPrefix) {
                    layer.isVisible = self.displayableItems.hasElements
                }
            }
        }
    }

    @ObservationIgnored
    var mapStyleLayer: HudHudMapLayer? {
        get {
            access(keyPath: \.mapStyleLayer)
            guard let data = UserDefaults.standard.value(forKey: "mapStyleLayer") as? Data else { return nil }

            return try? JSONDecoder().decode(HudHudMapLayer.self, from: data)
        }
        set {
            withMutation(keyPath: \.mapStyleLayer) {
                guard let data = try? JSONEncoder().encode(newValue) else { return }

                UserDefaults.standard.set(data, forKey: "mapStyleLayer")
            }
        }
    }

    var trackingState: TrackingState = .none {
        didSet {
            switch self.trackingState {
            case .none:
                break
            case .waitingForLocation:
                break
            case .locateOnce:
                Task {
                    guard let location = await self.userLocationStore.location() else { return }

                    self.camera = .center(location.coordinate, zoom: 14, reason: .programmatic)
                }
            case .keepTracking:
                self.camera = .trackUserLocationWithCourse(zoom: 16)
            }
        }
    }

    var camera: MapViewCamera = .center(.riyadh, zoom: 10) {
        didSet {
            switch self.camera.lastReasonForChange {
            case .gesturePan:
                self.trackingState = .none

            case .gestureRotate:
                if self.trackingState == .keepTracking {
                    self.trackingState = .none
                }

            default:
                break
            }
        }
    }

    var mapItems: [ResolvedItem] {
        let allItems = Set(self.displayableItems)

        if let selectedItem = selectedItem.value {
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
            if let selectedItem = selectedItem.value {
                let feature = MLNPointFeature(coordinate: selectedItem.coordinate)
                feature.attributes["poi_id"] = selectedItem.id
                feature
            }
        }
    }

    // MARK: Lifecycle

    init(camera: MapViewCamera = .center(.riyadh, zoom: 10), userLocationStore: UserLocationStore) {
        self.camera = camera
        self.userLocationStore = userLocationStore
        self.selectedItem = CurrentValueSubject(nil)
    }

    // MARK: Functions

    // MARK: - Internal

    // MARK: poi items functions

    func replaceItemsAndFocusCamera(on items: [DisplayableRow]) {
        self.displayableItems = items
        self.updateCamera(state: .mapItems)
    }

    func clearListAndSelect(_ item: ResolvedItem) {
        self.selectedItem.value = item
        self.displayableItems = [DisplayableRow.resolvedItem(item)]
    }

    func unselectItem() {
        self.selectedItem.value = nil
    }

    func show(_ item: ResolvedItem, shouldFocusCamera: Bool = false) {
        self.selectedItem.value = item
        if shouldFocusCamera {
            self.updateCamera(state: .selectedItem(item))
        }
    }

    func clearItems(clearResults: Bool = true) {
        self.selectedItem.value = nil
        if clearResults == true {
            self.displayableItems = []
        }
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

    func updateCamera(state: CameraUpdateState) {
        switch state {
        // show the whole route on the map
        case let .route(result):

            if let route = result {
                let boundingBox = route.bbox
                let coordinateBounds = MLNCoordinateBounds(sw: boundingBox.sw.clLocationCoordinate2D, ne: boundingBox.ne.clLocationCoordinate2D)
                self.camera = MapViewCamera.boundingBox(coordinateBounds,
                                                        edgePadding: UIEdgeInsets(top: 40, left: 40, bottom: 60, right: 40))
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

    func switchToNextTrackingAction() {
        switch self.trackingState {
        case .none:
            self.trackingState = .waitingForLocation
            self.trackingState = .locateOnce
            Logger.mapInteraction.log("None action required")
        case .waitingForLocation:
            Logger.mapInteraction.log("waiting for location")
        case .locateOnce:
            self.trackingState = .keepTracking
            Logger.mapInteraction.log("locate me Once")
        case .keepTracking:
            self.trackingState = .locateOnce
            Logger.mapInteraction.log("keep Tracking of user location")
        }
    }

    func isSFSymbolLayerPresent() -> Bool {
        return self.mapStyle?.layers.contains(where: { $0.identifier == MapLayerIdentifier.restaurants || $0.identifier == MapLayerIdentifier.shops }) ?? false
    }
}

// MARK: - Previewable

extension MapStore: Previewable {

    static let storeSetUpForPreviewing = MapStore(userLocationStore: .storeSetUpForPreviewing)
}

// MARK: - Private

private extension MapStore {

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
