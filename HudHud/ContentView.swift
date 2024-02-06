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

struct ContentView: View {

	@State private var camera = MapViewCamera.center(.vienna, zoom: 12)
	@State var selectedDetent: PresentationDetent = .large
	@State var isShown: Bool = true

	private let availableDetents: [PresentationDetent] = [.small, .medium, .large]

	var body: some View {
#if DEBUG
		if #available(iOS 17.1, *) {
			Self._logChanges()
		}
#endif
		return MapView(camera: $camera)
			.ignoresSafeArea()
			.safeAreaInset(edge: .top, alignment: .trailing) {
				CurrentLocationButton(camera: $camera)
					.padding()
			}
			.sheet(isPresented: .constant(true)) {
				BottomSheetView(camera: $camera, selectedDetent: $selectedDetent)
					.presentationDetents([.small, .medium, .large], selection: $selectedDetent)
					.presentationDragIndicator(.hidden)
					.presentationBackgroundInteraction(
						.enabled(upThrough: .medium)
					)
					.interactiveDismissDisabled()
					.ignoresSafeArea()
			}
	}
}

extension PresentationDetent {
	static let small: PresentationDetent = .height(100)
	static let third: PresentationDetent = .fraction(0.33)
}

extension CLLocationCoordinate2D {
	static let vienna = CLLocationCoordinate2D(latitude: 48.21, longitude: 16.37)
}

#Preview {
	ContentView()
}
