//
//  StreetViewStore.swift
//  HudHud
//
//  Created by Patrick Kladek on 15.10.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import Combine
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import OSLog
import SwiftUI

// MARK: - StreetViewStore

@Observable @MainActor
final class StreetViewStore {

    // MARK: Properties

    var streetViewScene: StreetViewScene?
    var nearestStreetViewScene: StreetViewScene?
    var fullScreenStreetView: Bool = false
    var svimage: UIImage?
    var svimageId: String = ""
    var errorMsg: String?
    var isLoading: Bool = false
    var progress: Float = 0
    var mapStore: MapStore
    var streetViewClient = StreetViewClient()
    var cachedScenes = [Int: StreetViewScene]()

    // MARK: Computed Properties

    var streetViewSource: ShapeSource {
        ShapeSource(identifier: "street-view-point") {
            if let coordinates = self.streetViewScene?.coordinates {
                let streetViewPoint = StreetViewPoint(coordinates: coordinates,
                                                      heading: 0)
                streetViewPoint.feature
            }
        }
    }

    // MARK: Lifecycle

    init(streetViewScene: StreetViewScene? = nil, nearestStreetViewScene: StreetViewScene? = nil, fullScreenStreetView: Bool = false, mapStore: MapStore, streetViewClient: StreetViewClient = StreetViewClient(), cachedScenes: [Int: StreetViewScene] = [Int: StreetViewScene]()) {
        self.streetViewScene = streetViewScene
        self.nearestStreetViewScene = nearestStreetViewScene
        self.fullScreenStreetView = fullScreenStreetView
        self.streetViewClient = streetViewClient
        self.cachedScenes = cachedScenes
        self.mapStore = mapStore
    }

    // MARK: Functions

    func loadStreetViewScene(id: Int) async {
        if let item = self.cachedScenes[id] {
            self.streetViewScene = item
            return
        }

        do {
            if let streetViewScene = try await self.streetViewClient.getStreetViewScene(id: id, baseURL: DebugStore().baseURL) {
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
            if let streetViewScene = try await self.streetViewClient.getStreetViewScene(id: id, baseURL: DebugStore().baseURL) {
                self.cachedScenes[streetViewScene.id] = streetViewScene
            }
        } catch {
            Logger.streetViewScene.error("Loading StreetViewScene failed \(error)")
        }
    }

    func zoomToStreetViewLocation() {
        guard let lat = streetViewScene?.lat else { return }
        guard let lon = streetViewScene?.lon else { return }

        self.mapStore.camera = .center(CLLocationCoordinate2D(latitude: lat, longitude: lon),
                                       zoom: 15,
                                       pitch: 0,
                                       pitchRange: .fixed(0))
    }

    func loadNearestStreetView(minLon: Double, minLat: Double, maxLon: Double, maxLat: Double) async {
        do {
            self.nearestStreetViewScene = try await self.streetViewClient.getStreetViewSceneBBox(box: [minLon, minLat, maxLon, maxLat])
        } catch {
            self.nearestStreetViewScene = nil
            Logger.streetViewScene.error("Loading StreetViewScene failed \(error)")
        }
    }

    func loadNearestStreetView(for _: CLLocationCoordinate2D) async {
        do {
            // This is not working as `getStreetView` doesn't return a scene but the older format
            // This means we could show the streetView Image but not navigate around
//            self.nearestStreetViewScene = try await self.streetViewClient.getStreetView(lat: location.latitude, lon: location.longitude, baseURL: DebugStore().baseURL)
        } catch {
            self.nearestStreetViewScene = nil
            Logger.streetViewScene.error("Loading StreetViewScene failed \(error)")
        }
    }
}

// MARK: - Previewable

extension StreetViewStore: Previewable {

    static let storeSetUpForPreviewing = StreetViewStore(mapStore: .storeSetUpForPreviewing)

}
