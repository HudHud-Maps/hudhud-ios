//
//  Street360View.swift
//  HudHud
//
//  Created by Aziz Dev on 10/07/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import SwiftUI
import SwiftUIPanoramaViewer

struct Street360View: View {

    var streetViewItem: StreetViewItem
    @State var mapStore: MapStore

    @State var rotationIndicator: Float = 0.0
    @State var expandView: Bool = false

    @State var svimage: UIImage?
    @State var errorMsg: String?

    var expandedView: (_ expand: Bool) -> Void
    var closeView: () -> Void

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
                } else {
                    VStack {
                        ProgressView()
                            .tint(.white)
                        Text("Loading...")
                            .foregroundStyle(.white)
                    }
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
                            self.expandView.toggle()
                        }
                        self.expandedView(self.expandView)

                    } label: {
                        Image(systemSymbol: self.expandView ? .arrowDownRightAndArrowUpLeftCircleFill : .arrowUpLeftAndArrowDownRightCircleFill)
                            .resizable()
                            .frame(width: 26, height: 26)
                            .accentColor(.white)
                            .shadow(radius: 26)
                    }
                }
                Spacer()
            }
            .padding(.top, self.expandView ? 64 : 16)
            .padding(.horizontal, 16)
        }
        .background(Color.black)
        .cornerRadius(16)
        .frame(width: UIScreen.main.bounds.width - (self.expandView ? 0 : 20),
               height: UIScreen.main.bounds.height - (self.expandView ? 0 : UIScreen.main.bounds.height / 1.5))
        .ignoresSafeArea()
        .padding(.top, self.expandView ? 0 : 60)
        .onAppear(perform: {
            PanoramaManager.shouldUpdateImage = true
            PanoramaManager.shouldResetCameraAngle = false
        })
        .onAppear {
            self.loadSVImage()
        }
    }

    // MARK: - Internal

    func dismissView() {
        self.closeView()
        // Do any cleanup...
    }

    func setMessage(_ msg: String) {
        self.errorMsg = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.dismissView()
        }
    }

    func loadSVImage() {
        guard let url = URL(string: streetViewItem.imageURL) else {
            self.setMessage("Invalid URL")
            return
        }

        DispatchQueue.global().async {
            do {
                // TODO: Update to cache the image
                let data = try Data(contentsOf: url)
                DispatchQueue.main.async {
                    self.svimage = UIImage(data: data)
                }
            } catch {
                DispatchQueue.main.async {
                    self.setMessage("Could not load the image - \(error.localizedDescription)")
                }
            }
        }
    }

    func panoramaView(_ img: UIImage) -> some View {
        ZStack {
            PanoramaViewer(image: SwiftUIPanoramaViewer.bindImage(img),
                           controlMethod: .touch) { key in
                print(key)
            } cameraMoved: { pitch, yaw, roll in
                DispatchQueue.main.async {
                    self.rotationIndicator = yaw
                }
                print("-=-=-=-=-=-=-")
                print("pitch: \(pitch)")
                print("yaw: \(yaw)")
                print("roll: \(roll)")
                print("-=-=-=-=-=-=-")
            }
            .onTapGesture {
                print(self.rotationIndicator)
            }

            VStack {
                Spacer()
                HStack {
                    CompassView()
                        .frame(width: 50.0, height: 50.0)
                        .rotationEffect(Angle(degrees: Double(self.rotationIndicator)))
                    Spacer()
                }
                .padding()
            }
        }
    }
}
