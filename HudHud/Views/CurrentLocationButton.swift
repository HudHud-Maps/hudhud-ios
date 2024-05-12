//
//  CurrentLocationButton.swift
//  HudHud
//
//  Created by Patrick Kladek on 31.01.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import MapLibre
import MapLibreSwiftUI
import OSLog
import SFSafeSymbols
import SwiftLocation
import SwiftUI

struct CurrentLocationButton: View {
	@State private var locationRequestInProgress = false
	@Binding var camera: MapViewCamera

	var body: some View {
		Button {
			withAnimation {
				self.camera = MapViewCamera.trackUserLocation(zoom: self.camera.zoom ?? MapViewCamera.Defaults.zoom)
			}
		} label: {
			if self.locationRequestInProgress {
				ProgressView()
					.font(.title2)
					.padding(13)
					.foregroundColor(.gray)
			} else {
				Image(systemSymbol: .location)
					.font(.title2)
					.padding(10)
					.foregroundColor(.gray)
			}
		}
		.background(Color.white)
		.cornerRadius(15)
		.shadow(color: .black.opacity(0.1), radius: 10, y: 4)
		.fixedSize()
		.disabled(self.locationRequestInProgress)
	}
}

@available(iOS 17, *)
#Preview(traits: .sizeThatFitsLayout) {
	@State var camera: MapViewCamera = .default()
	return CurrentLocationButton(camera: $camera)
		.padding()
}
