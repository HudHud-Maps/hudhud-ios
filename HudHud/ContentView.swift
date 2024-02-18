//
//  ContentView.swift
//  HudHud
//
//  Created by Patrick Kladek on 29.01.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import POIService
import SFSafeSymbols
import SwiftUI

struct ContentView: View {

	// NOTE: As a workaround until Toursprung prvides us with an endpoint that services this file
	private let styleURL = Bundle.main.url(forResource: "Terrain", withExtension: "json")!	// swiftlint:disable:this force_unwrapping

	@State private var camera = MapViewCamera.center(.vienna, zoom: 12)
	@State private var selectedPOI: POI?
	@State var selectedDetent: PresentationDetent = .small
	@State var isShown: Bool = true

	private let availableDetents: [PresentationDetent] = [.small, .medium, .large]

	var body: some View {
		return MapView(styleURL: styleURL, camera: $camera) {
			if let selectedPOI {
				let pointSource = ShapeSource(identifier: "points") {
					MLNPointFeature(coordinate: selectedPOI.locationCoordinate)
				}

				CircleStyleLayer(identifier: "simple-circles", source: pointSource)
					.radius(constant: 16)
					.color(constant: .systemRed)
					.strokeWidth(constant: 2)
					.strokeColor(constant: .white)
				SymbolStyleLayer(identifier: "simple-symbols", source: pointSource)
					.iconImage(constant: UIImage(systemSymbol: .mappin).withRenderingMode(.alwaysTemplate))
					.iconColor(constant: .white)
			} else {
				print("clear poi")
			}
		}
		.ignoresSafeArea()
		.safeAreaInset(edge: .top, alignment: .trailing) {
			CurrentLocationButton(camera: $camera)
				.padding()
		}
		.sheet(isPresented: .constant(true)) {
			BottomSheetView(viewModel: .init(),
							camera: $camera,
							selectedPOI: $selectedPOI,
							selectedDetent: $selectedDetent)
			.presentationCornerRadius(21)
			.presentationDetents([.small, .medium, .large], selection: $selectedDetent)
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
