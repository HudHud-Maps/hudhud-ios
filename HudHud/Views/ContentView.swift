//
//  ContentView.swift
//  HudHud
//
//  Created by Patrick Kladek on 29.01.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Combine
import CoreLocation
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import POIService
import SFSafeSymbols
import SwiftLocation
import SwiftUI
import ToursprungPOI

// MARK: - ContentView

@MainActor
struct ContentView: View {

	// NOTE: As a workaround until Toursprung prvides us with an endpoint that services this file
	private let styleURL = Bundle.main.url(forResource: "Terrain", withExtension: "json")! // swiftlint:disable:this force_unwrapping
	private let locationManager = Location()

	@StateObject private var searchViewStore: SearchViewStore
	@StateObject private var mapStore = MapStore()
	@State private var showUserLocation: Bool = false

	var body: some View {
		return MapView(styleURL: self.styleURL, camera: self.$mapStore.camera) {
			let pointSource = self.mapStore.mapItemStatus.points

			CircleStyleLayer(identifier: "simple-circles", source: pointSource)
				.radius(constant: 16)
				.color(constant: .systemRed)
				.strokeWidth(constant: 2)
				.strokeColor(constant: .white)
			SymbolStyleLayer(identifier: "simple-symbols", source: pointSource)
				.iconImage(constant: UIImage(systemSymbol: .mappin).withRenderingMode(.alwaysTemplate))
				.iconColor(constant: .white)
		}
		.unsafeMapViewModifier { mapView in
			mapView.showsUserLocation = self.showUserLocation
		}
		.task {
			for await event in await self.locationManager.startMonitoringAuthorization() {
				print("Authorization status did change: \(event.authorizationStatus)")
				self.showUserLocation = event.authorizationStatus.allowed
			}
		}
		.task {
			self.showUserLocation = self.locationManager.authorizationStatus.allowed
		}
		.ignoresSafeArea()
		.safeAreaInset(edge: .top, alignment: .trailing) {
			VStack(alignment: .trailing) {
				CurrentLocationButton(camera: self.$mapStore.camera)
				ProviderButton(searchViewStore: self.searchViewStore)
			}
			.padding()
		}
		.sheet(isPresented: self.$mapStore.searchShown) {
			SearchSheet(mapStore: self.mapStore,
						searchStore: self.searchViewStore)
				.presentationCornerRadius(21)
				.presentationDetents([.small, .medium, .large], selection: self.$searchViewStore.selectedDetent)
				.presentationBackgroundInteraction(
					.enabled(upThrough: .medium)
				)
				.interactiveDismissDisabled()
				.ignoresSafeArea()
		}
	}

	// MARK: - Lifecycle

	@MainActor
	init(searchViewStore: SearchViewStore, mapStore: MapStore = MapStore()) {
		self._searchViewStore = .init(wrappedValue: searchViewStore)
		self._mapStore = .init(wrappedValue: mapStore)
		searchViewStore.mapStore = mapStore
	}

	// MARK: - Internal
}

extension PresentationDetent {
	static let small: PresentationDetent = .height(100)
	static let third: PresentationDetent = .fraction(0.33)
}

extension CLLocationCoordinate2D {
	static let riyadh = CLLocationCoordinate2D(latitude: 24.71, longitude: 46.67)
}

#Preview {
	return ContentView(searchViewStore: .preview)
}
