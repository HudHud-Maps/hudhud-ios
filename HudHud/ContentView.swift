//
//  ContentView.swift
//  HudHud
//
//  Created by Patrick Kladek on 29.01.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI
import CoreLocation
import MapLibreSwiftUI

private let vienna = CLLocationCoordinate2D(latitude: 48.21, longitude: 16.37)

struct ContentView: View {

	@State private var camera = MapViewCamera.center(vienna, zoom: 12)

	var body: some View {
		ZStack(alignment: .topTrailing) {
			MapView(camera: $camera)
				.ignoresSafeArea()

			CurrentLocationButton(camera: $camera)
				.padding(.trailing, 16)
				.padding(.top, 16)
		}
	}
}

#Preview {
	ContentView()
}
