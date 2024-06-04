//
//  MapStore.swift
//  HudHud
//
//  Created by Patrick Kladek on 23.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation
import MapboxDirections
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import POIService
import SwiftUI

// MARK: - MapStore

final class MapStore: ObservableObject {

    enum StreetViewOption: Equatable {
        case disabled
        case requestedCurrentLocation
        case enabled
    }

    enum CameraUpdateState {
        case route(Toursprung.RouteCalculationResult?)
        case selectedItem(ResolvedItem)
        case userLocation(CLLocationCoordinate2D)
        case mapItems
        case defaultLocation
    }

    var locationManager = CLLocationManager()
    let motionViewModel: MotionViewModel
    var moveToUserLocation = false
    @Published var camera = MapViewCamera.center(.riyadh, zoom: 10)
    @Published var searchShown: Bool = true
    @Published var streetView: StreetViewOption = .disabled
    @Published var waypoints: [ABCRouteConfigurationItem]?

    @Published var routes: Toursprung.RouteCalculationResult? {
        didSet {
            updateCamera(state: .route(self.routes))
        }
    }

    @Published var currentLocation: CLLocationCoordinate2D? {
        didSet {
            self.moveToUserLocation = true
            if let currentLocation {
                updateCamera(state: .userLocation(currentLocation))
            }
        }
    }

    @Published var displayableItems: [AnyDisplayableAsRow] = [] {
        didSet {
            guard self.displayableItems != [] else { return }
            updateCamera(state: .mapItems)
        }
    }

    @Published var selectedItem: ResolvedItem? {
        didSet {
            if let selectedItem, routes == nil {
                updateCamera(state: .selectedItem(selectedItem))
            } else {
                return
            }
        }
    }

    var mapItems: [ResolvedItem] {
        let allItems: Set<AnyDisplayableAsRow> = Set(self.displayableItems)

        if let selectedItem {
            let items = allItems.union([AnyDisplayableAsRow(selectedItem)])
            return items.compactMap { $0.innerModel as? ResolvedItem }
        }

        return self.displayableItems.compactMap { $0.innerModel as? ResolvedItem }
    }

    var points: ShapeSource {
        return ShapeSource(identifier: MapSourceIdentifier.points, options: [.clustered: true, .clusterRadius: 44]) {
            self.mapItems.compactMap { item in
                return MLNPointFeature(coordinate: item.coordinate) { feature in
                    feature.attributes["poi_id"] = item.id
                }
            }
        }
    }

    var routePoints: ShapeSource {
        var features: [MLNPointFeature] = []
        if let waypoints = self.waypoints {
            for item in waypoints {
                switch item {
                case .myLocation:
                    continue
                case let .waypoint(poi):
                    let feature = MLNPointFeature(coordinate: poi.coordinate)
                    feature.attributes["poi_id"] = poi.id
                    features.append(feature)
                }
            }
        }
        return ShapeSource(identifier: MapSourceIdentifier.routePoints) {
            features
        }
    }

    var streetViewSource: ShapeSource {
        ShapeSource(identifier: MapSourceIdentifier.streetViewSymbols) {
            if case .enabled = self.streetView, let coordinate = self.motionViewModel.coordinate {
                let streetViewPoint = StreetViewPoint(location: coordinate,
                                                      heading: self.motionViewModel.position.heading)
                streetViewPoint.feature
            }
        }
    }

    // MARK: - Lifecycle

    init(camera: MapViewCamera = MapViewCamera.center(.riyadh, zoom: 10), searchShown: Bool = true, motionViewModel: MotionViewModel) {
        self.camera = camera
        self.searchShown = searchShown
        self.motionViewModel = motionViewModel
    }

    // MARK: - Internal

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

    // MARK: - Private

    private func getCameraZoomLevel() -> Double {
        if case let .centered(
            onCoordinate: _,
            zoom: zoom,
            pitch: _,
            pitchRange: _,
            direction: _
        ) = camera.state {
            return zoom
        }
        return 0
    }

    private func getCameraCoordinate() -> CLLocationCoordinate2D {
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
    private func isAnyItemVisible() -> Bool {
        if let bounds = mapItems.map(\.coordinate).boundingBox() {
            return bounds.contains(coordinate: self.getCameraCoordinate())
        }
        return false
    }

    private func getNearestMapItemCoordinates() -> [CLLocationCoordinate2D]? {
        guard let userLocation = self.locationManager.location?.coordinate else { return nil }
        // Sort map items by distance to the user location
        let sortedItems = self.mapItems.sorted(by: {
            $0.coordinate.distance(to: userLocation) < $1.coordinate.distance(to: userLocation)
        })
        // Return the coordinates of the 4 nearest items, if available
        return Array(sortedItems.prefix(4)).map(\.coordinate)
    }

}

// MARK: - Previewable

extension MapStore: Previewable {

    static let storeSetUpForPreviewing = MapStore(motionViewModel: .storeSetUpForPreviewing)
}

// MARK: - Private

private extension MapStore {
    func updateCamera(state: CameraUpdateState) {
        switch state {
        // show the whole route on the map
        case let .route(routes):
            if let routes {
                if let route = routes.routes.first, let coordinates = route.coordinates, !coordinates.isEmpty {
                    if let camera = CameraState.boundingBox(from: coordinates) {
                        self.camera = camera
                    }
                }
            }

        case let .selectedItem(selectedItem):
            // if the item selected from multi-map items(nearby poi), the camera will not move
            // Hint: the pin should animate or change the color of it. no camera move need it
            if let bounds = mapItems.map(\.coordinate).boundingBox(),
               bounds.contains(coordinate: selectedItem.coordinate),
               mapItems.count > 1, !isAnyItemVisible() {
                let coordinates = self.mapItems.map(\.coordinate)
                if let camera = CameraState.boundingBox(from: coordinates) {
                    self.camera = camera
                }
            } else {
                if self.mapItems.count > 1 {
                    // do not show any move
                    self.camera.setZoom(self.getCameraZoomLevel())
                } else {
                    // if poi choosing from Resents or directly from the search it will zoom and center around it
                    self.camera = .center(selectedItem.coordinate, zoom: 15)
                }
            }
        case let .userLocation(userLocation):
            self.moveToUserLocation = false
            self.camera = MapViewCamera.center(userLocation, zoom: 15)

        case .mapItems:
            self.handleMapItems()

        default:
            self.camera = MapViewCamera.center(.riyadh, zoom: 16)
        }
    }

    private func handleMapItems() {
        switch self.mapItems.count {
        case 0:
            break // no items, do nothing
        case 1:
            // if there is only one item ...center around this location
            if let item = mapItems.first, routes == nil {
                self.camera = .center(item.coordinate, zoom: 16)
            }
        case 2...:
            // if there is more than 2 items on the map ...and the zoom level is under 13 ...zoom out and move the camera to show items
            if self.getCameraZoomLevel() <= 13 {
                var coordinates = self.mapItems.map(\.coordinate)
                if let userLocation = self.locationManager.location?.coordinate {
                    coordinates.append(userLocation)
                }
                if let camera = CameraState.boundingBox(from: coordinates) {
                    self.camera = camera
                }
            } else {
                // if the camera zooming in...zoom out a little bit and show the nearest 4 poi around me
                if self.isAnyItemVisible() || self.getCameraZoomLevel() >= 13 {
                    if let nearestCoordinates = getNearestMapItemCoordinates() {
                        var coordinatea = nearestCoordinates
                        if let userLocation = self.locationManager.location?.coordinate {
                            coordinatea.append(userLocation)
                        }
                        if let camera = CameraState.boundingBox(from: coordinatea) {
                            self.camera = camera
                        }
                    }
                } else {
                    // do not show any move
                    self.camera.setZoom(self.getCameraZoomLevel())
                }
            }
        default:
            break // should never occur
        }
    }
}

extension [CLLocationCoordinate2D] {
    func boundingBox() -> MLNCoordinateBounds? {
        guard !self.isEmpty else { return nil }

        var minLat = self.first!.latitude
        var maxLat = self.first!.latitude
        var minLon = self.first!.longitude
        var maxLon = self.first!.longitude

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
