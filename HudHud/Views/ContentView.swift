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

@MainActor
struct ContentView: View {

	// NOTE: As a workaround until Toursprung prvides us with an endpoint that services this file
	private let styleURL = Bundle.main.url(forResource: "Terrain", withExtension: "json")!	// swiftlint:disable:this force_unwrapping

	@State private var camera = MapViewCamera.center(.vienna, zoom: 12)
	@State private var selectedPOI: POI?
	@State var selectedDetent: PresentationDetent = .medium
	@State var searchShown: Bool = true
	@StateObject var searchViewModel: SearchViewModel = .init(mode: .live(provider: .apple)) 	// TODO: revert back to .apple

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
			}
		}
		.ignoresSafeArea()
		.safeAreaInset(edge: .top, alignment: .trailing) {
			VStack {
				CurrentLocationButton(camera: $camera)
					.padding()
				ProviderButton(searchViewModel: searchViewModel)
			}
		}
		.sheet(isPresented: $searchShown) {
			SearchSheet(viewModel: searchViewModel,
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
	ContentView(searchViewModel: .init(mode: .preview))
}