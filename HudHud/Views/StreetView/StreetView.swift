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
                        self.store.dismissView()
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
                if self.store.showLoading {
                    ProgressView(value: self.store.progress)
                        .tint(.white)
                }
            }
        }
        .background(Color.black)
        .frame(width: UIScreen.main.bounds.width,
               height: UIScreen.main.bounds.height / (self.store.fullScreenStreetView ? 1.0 : 3.0))
        .onAppear(perform: {
            self.store.loadSVImage()
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
            self.store.loadImage(direction)
        })
        .onChange(of: self.store.streetViewScene) { _, _ in
            self.store.isLoading = true
            self.store.progress = 0
            self.store.loadSVImage()
        }
    }
}
