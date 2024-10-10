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

    // MARK: Nested Types

    enum NavDirection: Int {
        case next
        case previous
        case east
        case west
    }

    // MARK: Properties

    @Binding var streetViewScene: StreetViewScene?
    @Binding var fullScreenStreetView: Bool

    @State var mapStore: MapStore
    @State var rotationIndicator: Float = 0.0
    @State var rotationZIndicator: Float = 0.0
    @MainActor @State var svimage: UIImage?
    @State var svimageId: String = ""
    @State var errorMsg: String?
    @State var isLoading: Bool = false
    @State var progress: Float = 0

    // MARK: Computed Properties

    var showLoading: Bool {
        (self.svimage == nil && self.errorMsg == nil) || self.isLoading
    }

    var loadingProgress: String {
        return self.progress > 0 ? "\n\(String(format: "%.2f", self.progress * 100.0))%" : ""
    }

    // MARK: Content

    var body: some View {
        ZStack {
            if self.svimage != nil {
                self.panoramaView(self.$svimage)
            } else {
                if let errorMsg {
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
                            self.fullScreenStreetView.toggle()
                        }

                    } label: {
                        Image(systemSymbol: self.fullScreenStreetView ? .arrowDownRightAndArrowUpLeftCircleFill : .arrowUpLeftAndArrowDownRightCircleFill)
                            .resizable()
                            .frame(width: 26, height: 26)
                            .accentColor(.white)
                            .shadow(radius: 26)
                    }
                }
                Spacer()
            }
            .padding(.top, self.fullScreenStreetView ? 64 : 16)
            .padding(.horizontal, 16)
        }
        .background(Color.black)
        .cornerRadius(16)
        .frame(width: UIScreen.main.bounds.width - (self.fullScreenStreetView ? 0 : 20),
               height: UIScreen.main.bounds.height - (self.fullScreenStreetView ? 0 : UIScreen.main.bounds.height / 1.5))
        .ignoresSafeArea()
        .padding(.top, self.fullScreenStreetView ? 0 : 60)
        .onAppear(perform: {
            self.loadSVImage()
        })
    }

    var streetNavigationButtons: some View {
        VStack {
            Spacer()

            VStack {
                Button {
                    loadImage(.previous)
                } label: {
                    Image(systemSymbol: .chevronUpCircleFill)
                        .resizable()
                        .frame(width: 36, height: 36)
                        .accentColor(.white)
                        .shadow(radius: 26)
                        .opacity(self.streetViewScene?.previousId != nil ? 1.0 : 0.0)
                }

                HStack {
                    Button {
                        loadImage(.west)
                    } label: {
                        Image(systemSymbol: .chevronLeftCircleFill)
                            .resizable()
                            .frame(width: 36, height: 36)
                            .accentColor(.white)
                            .shadow(radius: 26)
                            .opacity(self.streetViewScene?.westId != nil ? 1.0 : 0.0)
                    }

                    Spacer()
                        .frame(width: 52)

                    Button {
                        loadImage(.east)
                    } label: {
                        Image(systemSymbol: .chevronRightCircleFill)
                            .resizable()
                            .frame(width: 36, height: 36)
                            .accentColor(.white)
                            .shadow(radius: 26)
                            .opacity(self.streetViewScene?.eastId != nil ? 1.0 : 0.0)
                    }
                }

                Button {
                    loadImage(.next)
                } label: {
                    Image(systemSymbol: .chevronDownCircleFill)
                        .resizable()
                        .frame(width: 36, height: 36)
                        .accentColor(.white)
                        .shadow(radius: 26)
                        .opacity(self.streetViewScene?.nextId != nil ? 1.0 : 0.0)
                }
            }
            .rotation3DEffect(.degrees(Double(self.rotationIndicator)), axis: (x: 0, y: 0, z: 1))
            .rotation3DEffect(.degrees(Double(self.rotationZIndicator)), axis: (x: 1, y: 0, z: 0))
            .padding()
            .padding(.bottom, 44)
        }
    }

    func panoramaView(_ img: Binding<UIImage?>) -> some View {
        ZStack {
            PanoramaViewer(image: img, panoramaType: .spherical, controlMethod: .touch) { direction in
                Logger.streetView.info("direction: \(direction)")
            } cameraMoved: { pitch, yaw, _ in
                DispatchQueue.main.async {
                    self.rotationIndicator = yaw
                    self.rotationZIndicator = pitch * 2 + 30
                }
            }

            if self.fullScreenStreetView, self.showLoading == false {
                self.streetNavigationButtons
            }
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

        Logger.streetView.log("SVD: streetViewScene3: \(self.streetViewScene.debugDescription)")

        guard let imageName = self.streetViewScene?.name else {
            self.isLoading = false
            return
        }
        Logger.streetView.debug("loadSVImage Value: \(self.streetViewScene?.id ?? -1), \(imageName)")
        guard let url = self.getImageURL(imageName) else { return }

        Task {
            let imageTask = ImagePipeline.shared.imageTask(with: url)
            for await progress in imageTask.progress {
                self.progress = progress.fraction
            }
            let image = try await imageTask.image

            #if targetEnvironment(simulator)
                // Simulator will crash with full size images
                let resizedImage = image.resize(CGSize(width: image.size.width / 2.0, height: image.size.height / 2.0))
            #else
                let resizedImage = image
            #endif

            PanoramaManager.shouldUpdateImage = true
            PanoramaManager.shouldResetCameraAngle = false
            self.svimage = resizedImage
            self.isLoading = false
        }
    }

    // MARK: - Internal

    func dismissView() {
        self.streetViewScene = nil
        self.fullScreenStreetView = false
    }

    func setMessage(_ msg: String) {
        self.errorMsg = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.dismissView()
        }
    }

}

extension StreetView {

    func loadImage(_ direction: NavDirection) {
        Task {
            let nextItem = self.getNextID(direction)
            guard let nextId = nextItem.id,
                  let nextName = nextItem.name else {
                return
            }
            Logger.streetView.debug("SVD: Direction: \(direction.rawValue), Value: \(nextId), \(nextName)")
            self.errorMsg = nil
            self.isLoading = true
            self.progress = 0.0
            await self.mapStore.loadStreetViewScene(id: nextId)
            Logger.streetView.log("SVD: streetViewScene1: \(self.streetViewScene.debugDescription)")
            self.loadSVImage()
        }
    }

    func getNextID(_ direction: NavDirection) -> (id: Int?, name: String?) {
        Logger.streetView.debug("SVD: Direction: \(direction.rawValue)")
        switch direction {
        case .next:
            return (self.streetViewScene?.nextId, self.streetViewScene?.nextName)
        case .previous:
            return (self.streetViewScene?.previousId, self.streetViewScene?.previousName)
        case .east:
            return (self.streetViewScene?.eastId, self.streetViewScene?.eastName)
        case .west:
            return (self.streetViewScene?.westId, self.streetViewScene?.westName)
        }
    }

    func preLoadScenes() {
        let nextItem = self.getNextID(.next)
        self.preLoadItem(nextItem.name)

        let previousItem = self.getNextID(.previous)
        self.preLoadItem(previousItem.name)

        Task {
            if let id = nextItem.id {
                await self.mapStore.preloadStreetViewScene(id: id)
            }
            if let id = previousItem.id {
                await self.mapStore.preloadStreetViewScene(id: id)
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

private extension UIImage {

    func resize(_ newSize: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        let image = UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }

        return image.withRenderingMode(renderingMode)
    }
}
