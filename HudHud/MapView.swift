//
//  MapView.swift
//  HudHud
//
//  Created by Patrick Kladek on 30.01.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import MapLibre
import SwiftUI
import MapLibreSwiftUI

struct MapView: View {
	private let styleURL = Bundle.main.url(forResource: "Terrain", withExtension: "json")
	@Binding var camera: MapViewCamera

	var body: some View {
		MapLibreSwiftUI.MapView(styleURL: styleURL!, camera: $camera) {

		}
	}
}

#Preview {
	let camera = MapViewCamera.default()
	return MapView(camera: .constant(camera))
		.ignoresSafeArea()
}
