//
//  MapStore.swift
//  HudHud
//
//  Created by Patrick Kladek on 23.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import CoreLocation
import Foundation
import MapboxDirections
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import OSLog
import SwiftUI

// MARK: - MapStore

final class MapStore: ObservableObject {

    enum StreetViewOption: Equatable {
        case disabled
        case requestedCurrentLocation
        case enabled
    }

    let motionViewModel: MotionViewModel

    @Published var camera = MapViewCamera.center(.riyadh, zoom: 10)
    @Published var searchShown: Bool = true
    @Published var streetView: StreetViewOption = .disabled

    @Published var selectedDetent: PresentationDetent = .small
    @Published var allowedDetents: Set<PresentationDetent> = [.small, .third, .large]
    @Published var trendingPOI: [ResolvedItem]?
    @Published var routes: Toursprung.RouteCalculationResult? {
        didSet {
            if let routes, self.path.contains(Toursprung.RouteCalculationResult.self) == false {
                self.path.append(routes)
                self.cameraTask?.cancel()
                self.cameraTask = Task {
                    try await Task.sleep(nanoseconds: 400 * NSEC_PER_MSEC)
                    try Task.checkCancellation()
                    await MainActor.run {
                        updateCameraForMapItems()
                    }
                }
            }
        }
    }

    @Published var waypoints: [ABCRouteConfigurationItem]?

    @Published var path = NavigationPath() {
        didSet {
            do {
                let elements = try path.elements()
                print("path now: \(elements)")
                // DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) {
                self.updateSelectedSheetDetent(to: elements.last)
                // }

            } catch {
                print("update detent error: \(error)")
            }
        }
    }

    @Published var displayableItems: [AnyDisplayableAsRow] = [] {
        didSet {
            updateCameraForMapItems()
        }
    }

    @Published var selectedItem: ResolvedItem? {
        didSet {
            updateCameraForMapItems()
            if let selectedItem {
                self.path.append(selectedItem)
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

    var cameraTask: Task<Void, Error>?

    // MARK: - Lifecycle

    init(camera: MapViewCamera = MapViewCamera.center(.riyadh, zoom: 10), searchShown: Bool = true, motionViewModel: MotionViewModel) {
        self.camera = camera
        self.searchShown = searchShown
        self.motionViewModel = motionViewModel
    }

    // MARK: - Internal

    /**
     This function determines the appropriate sheet detent based on the current state of the map store and search text.

     Current Criteria:
     - If there are routes available or a selected item, the sheet detent is set to `.medium`.
     - If the search text is not empty, the sheet detent is set to `.medium`.
     - Otherwise, the sheet detent is set to `.small`.

     Important Note:
     This function relies on changes to the `mapStore.routes`, `mapStore.selectedItem`, and `searchText`. If additional criteria are added in the future (e.g., `mapItems`), ensure to:
     1. Update this function to include the new criteria.
     2. Set up the appropriate observers for the new criteria to call `updateSheetDetent`.

     Failure to do so can result in the function not updating the detent properly when the new criteria change.
     **/

    func updateSelectedSheetDetent(to navigationPathItem: Any?) {
        // If routes exist or an item is selected, use the medium detent

        guard let navigationPathItem else {
            self.allowedDetents = [.small, .third, .large]
            if self.mapItems.isEmpty {
                self.selectedDetent = .small
            } else {
                self.selectedDetent = .third
            }
            return
        }

        if let sheetSubview = navigationPathItem as? SheetSubView {
            switch sheetSubview {
            case .mapStyle:
                self.allowedDetents = [.small, .medium]
                self.selectedDetent = .medium
            case .debugView:
                self.allowedDetents = [.large]
                self.selectedDetent = .large
            case .navigationAddSearchView:
                self.allowedDetents = [.large]
                self.selectedDetent = .large
            }
        }
        if let _ = navigationPathItem as? ResolvedItem {
            self.allowedDetents = [.small, .third, .large]
            self.selectedDetent = .third
        }
        if let _ = navigationPathItem as? Toursprung.RouteCalculationResult {
            self.allowedDetents = [.height(150), .medium]
            self.selectedDetent = .medium
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

}

// MARK: - Previewable

extension MapStore: Previewable {

    static let storeSetUpForPreviewing = MapStore(motionViewModel: .storeSetUpForPreviewing)
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

    func updateCameraForMapItems() {
        if let routes = self.routes {
            if let route = routes.routes.first, let coordinates = route.coordinates, !coordinates.isEmpty {
                self.camera = MapViewCamera.boundingBox(self.generateMLNCoordinateBounds(from: coordinates)!, edgePadding: UIEdgeInsets(top: 40, left: 40, bottom: 60, right: 40))
            }
            return
        }
        if let selectedItem = self.selectedItem {
            // when an item is selected the camera behaves differently then when there isn't
            self.camera = .center(selectedItem.coordinate, zoom: 16)
        } else {
            switch self.mapItems.count {
            case 0:
                break // no items, do nothing

            case 1:
                guard let item = self.mapItems.first else {
                    return
                }
                self.camera = .center(item.coordinate, zoom: 16)

            case 2...:
                let coordinates = self.mapItems.map(\.coordinate)
                guard let camera = CameraState.boundingBox(from: coordinates) else { return }

                self.camera = camera
            default:
                break // should never occur
            }
        }
    }
}
