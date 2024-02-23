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

// MARK: - ContentView

@MainActor
struct ContentView: View {

	// NOTE: As a workaround until Toursprung prvides us with an endpoint that services this file
	private let styleURL = Bundle.main.url(forResource: "Terrain", withExtension: "json")! // swiftlint:disable:this force_unwrapping

	@State private var camera = MapViewCamera.center(.riyadh, zoom: 10)
	@State var selectedDetent: PresentationDetent = .small
	@State var searchShown: Bool = true
	@StateObject var searchViewStore: SearchViewStore = .init(mode: .live(provider: .toursprung))

	private let availableDetents: [PresentationDetent] = [.small, .medium, .large]

	var body: some View {
		return MapView(styleURL: self.styleURL, camera: self.$camera) {
			let pointSource = self.searchViewStore.mapItemsState.points

			CircleStyleLayer(identifier: "simple-circles", source: pointSource)
				.radius(constant: 16)
				.color(constant: .systemRed)
				.strokeWidth(constant: 2)
				.strokeColor(constant: .white)
			SymbolStyleLayer(identifier: "simple-symbols", source: pointSource)
				.iconImage(constant: UIImage(systemSymbol: .mappin).withRenderingMode(.alwaysTemplate))
				.iconColor(constant: .white)
		}
		.ignoresSafeArea()
		.safeAreaInset(edge: .top, alignment: .trailing) {
			VStack(alignment: .trailing) {
				CurrentLocationButton(camera: self.$camera)
				ProviderButton(searchViewStore: self.searchViewStore)
			}
			.padding()
		}
		.sheet(isPresented: self.$searchShown) {
			SearchSheet(viewStore: self.searchViewStore,
						camera: self.$camera,
						selectedDetent: self.$selectedDetent)
				.presentationCornerRadius(21)
				.presentationDetents([.small, .medium, .large], selection: self.$selectedDetent)
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
	static let riyadh = CLLocationCoordinate2D(latitude: 24.71, longitude: 46.67)
}

#Preview {
	@StateObject var store: SearchViewStore = .init(mode: .preview)
	return ContentView(searchViewStore: store)
}
