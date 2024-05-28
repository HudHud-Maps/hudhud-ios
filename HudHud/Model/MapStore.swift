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

    let motionViewModel: MotionViewModel

    @Published var camera = MapViewCamera.center(.riyadh, zoom: 10, pitch: 0, pitchRange: .fixed(0))
    @Published var searchShown: Bool = true
    @Published var streetView: StreetViewOption = .disabled
    @Published var routes: Toursprung.RouteCalculationResult?
    @Published var navigatingRoute: Route? {
        didSet {
            let newValue = self.navigatingRoute != nil
            guard newValue != self.navigationInProgress else { return }

            self.navigationInProgress = newValue
        }
    }

    @Published var navigationInProgress: Bool = false
    @Published var waypoints: [ABCRouteConfigurationItem]?

    @Published var displayableItems: [AnyDisplayableAsRow] = [] {
        didSet {
            updateCameraForMapItems()
        }
    }

    @Published var selectedItem: ResolvedItem? {
        didSet {
            updateCameraForMapItems()
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
}

// MARK: - Previewable

extension MapStore: Previewable {

    static let storeSetUpForPreviewing = MapStore(motionViewModel: .storeSetUpForPreviewing)
}

// MARK: - Private

private extension MapStore {

    func updateCameraForMapItems() {
        if let selectedItem {
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
