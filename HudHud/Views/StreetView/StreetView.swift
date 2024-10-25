//
//  StreetView.swift
//  HudHud
//
//  Created by Aziz Dev on 10/07/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import Nuke
import OSLog
import SwiftUI
import SwiftUIPanoramaViewer

// MARK: - StreetView

@MainActor
struct StreetView: View {

    // MARK: Properties

    var store: StreetViewStore
    @ObservedObject var debugStore: DebugStore

    // MARK: Computed Properties

    var showLoading: Bool {
        (self.store.svimage == nil && self.store.errorMsg == nil) || self.store.isLoading
    }

    var loadingProgress: String {
        return self.store.progress > 0 ? "\n\(String(format: "%.2f", self.store.progress * 100.0))%" : ""
    }

    // MARK: Content

    var body: some View {
        ZStack(alignment: .top) {
            self.panoramaView()
                .ignoresSafeArea()

            if let errorMsg = self.store.errorMsg {
                Text(errorMsg)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.yellow)
                    .padding()
                    .background(.black)
                    .cornerRadius(15)
            }

            VStack {
                HStack {
                    Button {
                        self.dismissView()
                    } label: {
                        Image(.arrowLeftCircleFill)
                            .frame(width: 44, height: 44)
                    }

                    Spacer()

                    Button {
                        withAnimation {
                            self.store.fullScreenStreetView.toggle()
                        }
                    } label: {
                        Image(self.store.fullScreenStreetView ? .minimizeCircleFill : .maximizeCircleFill)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 16)

                Spacer()
                if self.showLoading {
                    ProgressView(value: self.store.progress)
                        .tint(.white)
                }
            }
        }
        .background(Color.black)
        .frame(width: UIScreen.main.bounds.width,
               height: UIScreen.main.bounds.height / (self.store.fullScreenStreetView ? 1.0 : 3.0))
        .onAppear(perform: {
            self.loadSVImage()
        })
    }

    func panoramaView() -> some View {
        PanoramaViewer(image: Binding(get: {
            self.store.svimage
        }, set: { _ in

        }), panoramaType: .spherical, controlMethod: .touch, startAngle: .pi, rotationHandler: { rotation in
            // Callback for heading from streetView here
            self.store.heading = rotation.toDegrees()
        }, cameraMoved: { _, _, _ in

        }, tapHandler: { direction in
            self.loadImage(direction)
        })
        .onChange(of: self.store.streetViewScene) { _, _ in
            self.store.isLoading = true
            self.store.progress = 0
            self.loadSVImage()
        }
    }
}

// MARK: - Private

private extension StreetView {

    func loadImage(_ direction: CTNavigationDirection) {
        Task {
            let nextItem = self.getNextID(direction)
            guard let nextId = nextItem.id,
                  let nextName = nextItem.name else {
                return
            }
            Logger.streetView.debug("SVD: Direction: \(String(reflecting: direction)), Value: \(nextId), \(nextName)")
            self.store.errorMsg = nil
            self.store.isLoading = true
            self.store.progress = 0.0
            await self.store.loadStreetViewScene(id: nextId)
            if let coordinates = self.store.streetViewScene?.coordinates {
                self.store.mapStore.camera = .center(coordinates, zoom: self.store.mapStore.camera.zoom ?? 16)
            }
            Logger.streetView.log("SVD: streetViewScene1: \(self.store.streetViewScene.debugDescription)")
            self.loadSVImage()
        }
    }

    func getNextID(_ direction: CTNavigationDirection) -> (id: Int?, name: String?) {
        Logger.streetView.debug("SVD: Direction: \(direction.rawValue)")
        switch direction {
        case .north:
            return (self.store.streetViewScene?.nextId, self.store.streetViewScene?.nextName)
        case .south:
            return (self.store.streetViewScene?.previousId, self.store.streetViewScene?.previousName)
        case .east:
            return (self.store.streetViewScene?.eastId, self.store.streetViewScene?.eastName)
        case .west:
            return (self.store.streetViewScene?.westId, self.store.streetViewScene?.westName)
        }
    }

    func preLoadScenes() {
        let nextItem = self.getNextID(.north)
        self.preLoadItem(nextItem.name)

        let previousItem = self.getNextID(.south)
        self.preLoadItem(previousItem.name)

        Task {
            if let id = nextItem.id {
                await self.store.preloadStreetViewScene(id: id)
            }
            if let id = previousItem.id {
                await self.store.preloadStreetViewScene(id: id)
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

    func dismissView() {
        if let imgName = self.store.streetViewScene?.name, let url = self.getImageURL(imgName) {
            let imageTask = ImagePipeline.shared.imageTask(with: url)
            imageTask.cancel()
        }

        self.store.streetViewScene = nil
        self.store.fullScreenStreetView = false
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

        Logger.streetView.log("SVD: streetViewScene3: \(self.store.streetViewScene.debugDescription)")

        guard let imageName = self.store.streetViewScene?.name else {
            self.store.isLoading = false
            return
        }
        Logger.streetView.debug("loadSVImage Value: \(self.store.streetViewScene?.id ?? -1), \(imageName)")
        guard let url = self.getImageURL(imageName) else { return }

        Task {
            let imageTask = ImagePipeline.shared.imageTask(with: url)
            for await progress in imageTask.progress {
                self.store.progress = progress.fraction
            }
            var image = try await imageTask.image

            // Some older devices might crash with full size images
            // For testing we have the option to request full size images from the server
            // Once we agree on the right size & quality we will request compatible images
            // for every device, then we can remove this
            let targetSize = image.size.clipToMaximumSupportedTextureSize()
            if image.size.width > targetSize.width || image.size.height > targetSize.height {
                image = image.resize(targetSize, scale: 1)
            }

            PanoramaManager.shouldUpdateImage = true
            PanoramaManager.shouldResetCameraAngle = false
            self.store.svimage = image
            self.store.isLoading = false
        }
    }
}
