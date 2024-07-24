//
//  StreetViewV2.swift
//  HudHud
//
//  Created by Aziz Dev on 10/07/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import OSLog
import SwiftUI
import SwiftUIPanoramaViewer

// MARK: - StreetViewV2

struct StreetViewV2: View {

    @Binding var streetViewScene: StreetViewScene?
    @State var mapStore: MapStore
    @Binding var fullScreenStreetView: Bool

    @State var rotationIndicator: Float = 0.0
    @State var rotationZIndicator: Float = 0.0

    @State var svimage: UIImage?
    @State var svimageId: String = ""
    @State var errorMsg: String?

    @State var isLoading: Bool = false

    enum NavDirection { case next; case previous; case east; case west }

    var showLoading: Bool {
        (self.svimage == nil && self.errorMsg == nil) || self.isLoading
    }

    var body: some View {
        ZStack {
            if let svimage {
                self.panoramaView(svimage)
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
                    Text("Loading...")
                        .foregroundStyle(.white)
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
            PanoramaManager.shouldUpdateImage = false
            PanoramaManager.shouldResetCameraAngle = true
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
                        .frame(width: 26, height: 26)
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
                            .frame(width: 26, height: 26)
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
                            .frame(width: 26, height: 26)
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
                        .frame(width: 26, height: 26)
                        .accentColor(.white)
                        .shadow(radius: 26)
                        .opacity(self.streetViewScene?.nextId != nil ? 1.0 : 0.0)
                }
            }
            .rotationEffect(Angle(degrees: Double(self.rotationIndicator)))
            .rotation3DEffect(.degrees(Double(self.rotationZIndicator)), axis: (x: 1, y: 0, z: 0))
            .padding()
            .padding(.bottom, 44)
        }
    }

    // MARK: - Internal

    func dismissView() {
        self.streetViewScene = nil
        // Do any cleanup...
    }

    func setMessage(_ msg: String) {
        self.errorMsg = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.dismissView()
        }
    }

    func getImageURL(_ name: String) -> String {
        let link = "https://streetview.khaled-7ed.workers.dev/\(name)?api_key=34iAPI8sPcOI4eJCSstL9exd159tJJFmsnerjh"
        return link
    }

    func loadSVImage() {
        guard let imageName = self.streetViewScene?.name else { return }
        let link = self.getImageURL(imageName)

        DownloadManager.downloadFile(link, isThumb: false) { path, error in
            self.isLoading = false
            if let path {
                if self.svimageId != path {
                    self.svimageId = path
                    self.svimage = UIImage(contentsOfFile: path)
                }
            } else {
                self.setMessage("Could not load the image - \(error ?? "N/A")")
                Logger.streetViewScene.error("Could not load the image - \(error ?? "N/A")")
            }
        }
    }

    func panoramaView(_ img: UIImage) -> some View {
        ZStack {
            PanoramaViewer(image: SwiftUIPanoramaViewer.bindImage(img),
                           panoramaType: .spherical,
                           controlMethod: .touch) { key in
                Logger.panoramaView.info("\(key)")
            } cameraMoved: { pitch, yaw, roll in
                DispatchQueue.main.async {
                    self.rotationIndicator = yaw
                    self.rotationZIndicator = pitch * 2 + 30
                }
                Logger.panoramaView.info("pitch: \(pitch)  \n yaw: \(yaw) \n roll: \(roll)")
            }
            .id(img)

            VStack {
                Spacer()
                HStack {
                    CompassView()
                        .frame(width: 50.0, height: 50.0)
                        .rotationEffect(Angle(degrees: Double(self.rotationIndicator * -1)))
                    Spacer()
                }
                .padding()
            }

            if self.fullScreenStreetView, self.showLoading == false {
                self.streetNavigationButtons
            }
        }
    }

}

extension StreetViewV2 {

    func loadImage(_ direction: NavDirection) {
        Task {
            let nextItem = self.getNextID(direction)
            guard let nextId = nextItem.id else { return }
            guard let nextName = nextItem.name else { return }
            let link = self.getImageURL(nextName)
            if let path = DownloadManager.getLocalFilePath(link),
               let img = UIImage(contentsOfFile: path), svimageId != path {
                self.svimageId = path
                self.svimage = img

            } else {
                self.errorMsg = nil
                self.isLoading = true
            }

            await self.mapStore.loadStreetViewScene(id: nextId) { item in
                if let item {
                    self.streetViewScene = item
                    self.loadSVImage()
                } else {
                    self.isLoading = false
                }
            }
        }
    }

    func getNextID(_ direction: NavDirection) -> (id: Int?, name: String?) {
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

}
