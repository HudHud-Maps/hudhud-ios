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

struct StreetView: View {

    // MARK: Properties

    @Bindable var store: StreetViewStore

    // MARK: Computed Properties

    var showLoading: Bool {
        (self.store.svimage == nil && self.store.errorMsg == nil) || self.store.isLoading
    }

    var loadingProgress: String {
        return self.store.progress > 0 ? "\n\(String(format: "%.2f", self.store.progress * 100.0))%" : ""
    }

    // MARK: Content

    var body: some View {
        ZStack {
            if self.store.svimage != nil {
                self.panoramaView(self.$store.svimage)
            } else {
                if let errorMsg = self.store.errorMsg {
                    Text(errorMsg)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.red)
                        .padding()
                }
            }

            if self.showLoading {
                VStack {
                    ProgressView()
                        .tint(.white)
                    Text("Loading..." + self.loadingProgress)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }
            }

            VStack {
                HStack {
                    Button {
                        self.dismissView()
                    } label: {
                        Image(systemSymbol: .xCircleFill)
                            .resizable()
                            .frame(width: 26, height: 26)
                            .accentColor(.white)
                            .shadow(radius: 26)
                    }

                    Spacer()

                    Button {
                        withAnimation {
                            self.store.fullScreenStreetView.toggle()
                        }

                    } label: {
                        Image(systemSymbol: self.store.fullScreenStreetView ? .arrowDownRightAndArrowUpLeftCircleFill : .arrowUpLeftAndArrowDownRightCircleFill)
                            .resizable()
                            .frame(width: 26, height: 26)
                            .accentColor(.white)
                            .shadow(radius: 26)
                    }
                }
                Spacer()
            }
            .padding(.top, self.store.fullScreenStreetView ? 64 : 16)
            .padding(.horizontal, 16)
        }
        .background(Color.black)
        .cornerRadius(16)
        .frame(width: UIScreen.main.bounds.width - (self.store.fullScreenStreetView ? 0 : 20),
               height: UIScreen.main.bounds.height - (self.store.fullScreenStreetView ? 0 : UIScreen.main.bounds.height / 1.5))
        .ignoresSafeArea()
        .padding(.top, self.store.fullScreenStreetView ? 0 : 60)
        .onAppear(perform: {
            self.loadSVImage()
        })
    }

    func panoramaView(_ img: Binding<UIImage?>) -> some View {
        ZStack {
            PanoramaViewer(image: img, panoramaType: .spherical, controlMethod: .touch, startAngle: .pi, rotationHandler: { _ in
                // Callback for heading from streetView here
//                self.store.heading = rotation.toDegrees()
            }, cameraMoved: { _, _, _ in

            }, tapHandler: { direction in
                loadImage(direction)
            })
        }
    }

    // MARK: Functions

    func getImageURL(_ name: String) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "streetview.khaled-7ed.workers.dev"
        components.path = "/\(name)"
        components.queryItems = [
            URLQueryItem(name: "api_key", value: "34iAPI8sPcOI4eJCSstL9exd159tJJFmsnerjh")
        ]
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
            let image = try await imageTask.image

            #if targetEnvironment(simulator)
                // Simulator will crash with full size images
                let resizedImage = image.resize(CGSize(width: image.size.width / 2.0, height: image.size.height / 2.0), scale: 1)
            #else
                let resizedImage = image
            #endif

            PanoramaManager.shouldUpdateImage = true
            PanoramaManager.shouldResetCameraAngle = false
            self.store.svimage = resizedImage
            self.store.isLoading = false
        }
    }

    // MARK: - Internal

    func dismissView() {
        self.store.streetViewScene = nil
        self.store.fullScreenStreetView = false
    }

    func setMessage(_ msg: String) {
        self.store.errorMsg = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.dismissView()
        }
    }

}

extension StreetView {

    func loadImage(_ direction: CTNavigationDirection) {
        Task {
            let nextItem = self.getNextID(direction)
            guard let nextId = nextItem.id,
                  let nextName = nextItem.name else {
                return
            }
            Logger.streetView.debug("SVD: Direction: \(direction.rawValue), Value: \(nextId), \(nextName)")
            self.store.errorMsg = nil
            self.store.isLoading = true
            self.store.progress = 0.0
            await self.store.loadStreetViewScene(id: nextId)
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

    // Function to download and manually assign an image with caching
    func loadImageManually(url: URL, into imageView: UIImageView) {
        // Get a reference to the shared image pipeline
        let pipeline = ImagePipeline.shared

        // Load the image using the pipeline
        pipeline.loadImage(with: url) { result in
            switch result {
            case let .success(response):
                // Image successfully loaded, assign it to the imageView
                imageView.image = response.image

                // The image is automatically cached, no need to do anything extra
                Logger.streetView.info("Image loaded and cached successfully")
            case let .failure(error):
                // Handle failure
                Logger.streetView.error("Image loading failed: \(error)")
            }
        }
    }

    // Function to retrieve an image from cache if available
    func getCachedImage(url: URL) -> UIImage? {
        let pipeline = ImagePipeline.shared

        // Try to get the image from cache
        if let cachedImage = pipeline.cache[ImageRequest(url: url)]?.image {
            Logger.streetView.info("Image retrieved from cache")
            return cachedImage
        } else {
            Logger.streetView.info("Image not found in cache")
            return nil
        }
    }
}
