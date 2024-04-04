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
	var locationManager: Location

	var body: some View {
		Button {
			Task {
				defer { self.locationRequestInProgress = false }
				do {
					self.locationRequestInProgress = true
					self.locationManager.accuracy = .threeKilometers
					try await self.locationManager.requestPermission(.whenInUse)
					let userLocation = try await locationManager.requestLocation()

					if let coordinates = userLocation.location?.coordinate {
						withAnimation {
							self.camera = MapViewCamera.center(coordinates, zoom: 10)
						}
					} else {
						Logger.searchView.error("location error: got no coordinates")
					}
				} catch {
					Logger.searchView.error("location error: \(error)")
				}
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
	return CurrentLocationButton(camera: $camera, locationManager: .init())
		.padding()
}
