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
import Nuke
import OSLog
import SwiftUI
import SwiftUIPanoramaViewer

// MARK: - StreetViewStore

@Observable @MainActor
final class StreetViewStore {

    // MARK: Properties

    @ObservationIgnored weak var currentImageTask: ImageTask?
    @ObservationIgnored var debugStore: DebugStore

    var heading: Float = 0
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

    var showLoading: Bool {
        return (self.svimage == nil && self.errorMsg == nil) || self.isLoading
    }

    // MARK: Lifecycle

    init(streetViewScene: StreetViewScene? = nil, nearestStreetViewScene: StreetViewScene? = nil, fullScreenStreetView: Bool = false,
         mapStore: MapStore, streetViewClient: StreetViewClient = StreetViewClient(), debugStore: DebugStore = DebugStore(),
         cachedScenes: [Int: StreetViewScene] = [Int: StreetViewScene]()) {
        self.streetViewScene = streetViewScene
        self.nearestStreetViewScene = nearestStreetViewScene
        self.fullScreenStreetView = fullScreenStreetView
        self.streetViewClient = streetViewClient
        self.cachedScenes = cachedScenes
        self.mapStore = mapStore
        self.debugStore = debugStore
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
                self.errorMsg = nil
                self.streetViewScene = streetViewScene
                self.cachedScenes[streetViewScene.id] = streetViewScene
            }
        } catch {
            Logger.streetViewScene.error("Loading StreetViewScene failed \(error)")
            self.errorMsg = error.localizedDescription
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
            self.nearestStreetViewScene = try await self.streetViewClient.getStreetViewSceneBBox(box: [minLon, minLat, maxLon, maxLat],
                                                                                                 baseURL: DebugStore().baseURL)
            self.errorMsg = nil
        } catch {
            self.nearestStreetViewScene = nil
            Logger.streetViewScene.error("Loading StreetViewScene failed \(error)")
            self.errorMsg = error.localizedDescription
        }
    }

    func loadNearestStreetView(for coordinate: CLLocationCoordinate2D) async {
        do {
            // This is not working as `getStreetView` doesn't return a scene but the older format
            // This means we could show the streetView Image but not navigate around
            self.streetViewScene = try await self.streetViewClient.getStreetView(lat: coordinate.latitude, lon: coordinate.longitude,
                                                                                 baseURL: DebugStore().baseURL)
            self.errorMsg = nil
        } catch {
            self.streetViewScene = nil
            Logger.streetViewScene.error("Loading StreetViewScene failed \(error)")
            self.errorMsg = error.localizedDescription
        }
    }

    func loadImage(_ direction: CTNavigationDirection) {
        Task {
            let nextItem = self.getNextID(direction)
            guard let nextId = nextItem.id,
                  let nextName = nextItem.name else {
                return
            }
            Logger.streetView.debug("SVD: Direction: \(String(reflecting: direction)), Value: \(nextId), \(nextName)")
            self.errorMsg = nil
            self.isLoading = true
            self.progress = 0.0
            await self.loadStreetViewScene(id: nextId)
            if let coordinates = self.streetViewScene?.coordinates {
                self.mapStore.camera = .center(coordinates, zoom: self.mapStore.camera.zoom ?? 16)
            }
            Logger.streetView.log("SVD: streetViewScene1: \(self.streetViewScene.debugDescription)")
            self.loadSVImage()
        }
    }

    func getNextID(_ direction: CTNavigationDirection) -> (id: Int?, name: String?) {
        Logger.streetView.debug("SVD: Direction: \(direction.rawValue)")
        switch direction {
        case .north:
            return (self.streetViewScene?.nextId, self.streetViewScene?.nextName)
        case .south:
            return (self.streetViewScene?.previousId, self.streetViewScene?.previousName)
        case .east:
            return (self.streetViewScene?.eastId, self.streetViewScene?.eastName)
        case .west:
            return (self.streetViewScene?.westId, self.streetViewScene?.westName)
        }
    }

    func preLoadScenes() {
        let nextItem = self.getNextID(.north)
        self.preLoadItem(nextItem.name)

        let previousItem = self.getNextID(.south)
        self.preLoadItem(previousItem.name)

        Task {
            if let id = nextItem.id {
                await self.preloadStreetViewScene(id: id)
            }
            if let id = previousItem.id {
                await self.preloadStreetViewScene(id: id)
            }
        }
    }

    func preLoadItem(_ imgName: String?) {
        guard let imgName else { return }
        guard let url = self.getImageURL(imgName) else { return }

        Task {
            do {
                let imageTask = ImagePipeline.shared.imageTask(with: url)
                _ = try await imageTask.image
                Logger.streetView.debug("Done preLoadItem: \(imageTask.description)")
            } catch {
                Logger.streetView.debug("preLoadItem error: \(error)")
            }
        }
    }

    func getImageURL(_ name: String) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "streetview.dev.hudhud.sa"
        components.path = "/\(name)"
        components.queryItems = [
            URLQueryItem(name: "api_key", value: "34iAPI8sPcOI4eJCSstL9exd159tJJFmsnerjh")
        ]

        if let format = self.debugStore.streetViewQuality.format {
            components.queryItems?.append(URLQueryItem(name: "format", value: format))
        }

        if let size = self.debugStore.streetViewQuality.size {
            let clipped = size.clipToMaximumSupportedTextureSize()
            components.queryItems?.append(URLQueryItem(name: "width", value: "\(clipped.width)"))
            components.queryItems?.append(URLQueryItem(name: "height", value: "\(clipped.height)"))
        }
        if let quality = self.debugStore.streetViewQuality.quality {
            components.queryItems?.append(URLQueryItem(name: "quality", value: "\(quality)"))
        }

        Logger.streetView.debug("Parameters: \(components.queryItems ?? [])")

        return components.url
    }

    func loadSVImage() {
        // we will attempt to preload next and previous images if its not yet loaded
        self.preLoadScenes()

        Logger.streetView.log("SVD: streetViewScene3: \(self.streetViewScene.debugDescription)")

        guard let imageName = self.streetViewScene?.name else {
            self.isLoading = false
            return
        }
        Logger.streetView.debug("loadSVImage Value: \(self.streetViewScene?.id ?? -1), \(imageName)")
        guard let url = self.getImageURL(imageName) else { return }

        Task {
            do {
                self.currentImageTask?.cancel()

                let imageTask = ImagePipeline.shared.imageTask(with: url)
                self.currentImageTask = imageTask
                for await progress in imageTask.progress {
                    self.progress = progress.fraction
                }
                var image = try await imageTask.image

                // Some older devices might crash with full size images
                // For testing we have the option to request full size images from the server
                // Once we agree on the right size & quality we will request compatible images
                // for every device, then we can remove this
                let targetSize = image.imageSize.clipToMaximumSupportedTextureSize()
                if image.imageSize.width > targetSize.width || image.imageSize.height > targetSize.height {
                    image = image.resize(CGSize(width: targetSize.width, height: targetSize.height), scale: 1)
                }

                PanoramaManager.shouldUpdateImage = true
                PanoramaManager.shouldResetCameraAngle = false
                self.svimage = image
                self.isLoading = false
            } catch {
                if error is CancellationError { return }

                self.errorMsg = String(reflecting: error)
            }
        }
    }

    func dismissView() {
        if let imgName = self.streetViewScene?.name, let url = self.getImageURL(imgName) {
            let imageTask = ImagePipeline.shared.imageTask(with: url)
            imageTask.cancel()
        }

        self.streetViewScene = nil
        self.fullScreenStreetView = false
    }
}

// MARK: - Previewable

extension StreetViewStore: Previewable {

    static let storeSetUpForPreviewing = StreetViewStore(mapStore: .storeSetUpForPreviewing, debugStore: DebugStore())

}
