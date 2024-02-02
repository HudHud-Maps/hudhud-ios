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
	@State var isShown: Bool = true

	var body: some View {
		MapView(camera: $camera)
			.ignoresSafeArea()
			.safeAreaInset(edge: .top, alignment: .trailing) {
				CurrentLocationButton(camera: $camera)
					.padding()
			}
			.sheet(isPresented: .constant(true)) {
				BottomSheetView()
					.presentationDetents([.height(100), .medium, .large])
					.presentationBackgroundInteraction(
						.enabled(upThrough: .medium)
					)
					.interactiveDismissDisabled()
					.ignoresSafeArea()
			}
	}
}

#Preview {
	ContentView()
}
