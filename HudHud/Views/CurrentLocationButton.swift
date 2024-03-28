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

	@Binding var camera: MapViewCamera
	let location = Location()

	var body: some View {
		Button {
			Task {
				do {
					self.location.accuracy = .threeKilometers
					try await self.location.requestPermission(.whenInUse)
					let userLocation = try await location.requestLocation()

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
			Image(systemSymbol: .location)
				.font(.title2)
				.padding(10)
				.foregroundColor(.gray)
		}
		.background(Color.white)
		.cornerRadius(15)
		.shadow(color: .black.opacity(0.1), radius: 10, y: 4)
		.fixedSize()
//		.padding(12)
//		.frame(minWidth: 44, minHeight: 44)
//		.background {
//			RoundedRectangle(cornerRadius: 10)
//				.fill(Material.thickMaterial)
//		}
	}
}

@available(iOS 17, *)
#Preview(traits: .sizeThatFitsLayout) {
	@State var camera: MapViewCamera = .default()
	return CurrentLocationButton(camera: $camera)
		.padding()
}
