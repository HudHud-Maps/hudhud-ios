//
//  LocationButton.swift
//  HudHud
//
//  Created by Patrick Kladek on 31.01.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import MapLibre
import MapLibreSwiftUI
import SFSafeSymbols
import SwiftLocation
import SwiftUI

struct CurrentLocationButton: View {

	@Binding var camera: MapViewCamera

	var body: some View {
		Button {
			Task {
				do {
					let location = Location()
					try await location.requestPermission(.whenInUse)
					let userLocation = try await location.requestLocation()

					if let coordinates = userLocation.location?.coordinate {
						withAnimation {
							self.camera = MapViewCamera.center(coordinates, zoom: 10)
						}
					} else {
						print("location error: got no coordinates")
					}
				} catch {
					print("location error: \(error)")
				}
			}
		} label: {
			Image(systemSymbol: .location)
		}
		.padding(12)
		.frame(minWidth: 44, minHeight: 44)
		.background {
			RoundedRectangle(cornerRadius: 10)
				.fill(Material.regular)
		}
	}
}

#Preview {
	@State var camera: MapViewCamera = .default()
	return CurrentLocationButton(camera: $camera)
}
