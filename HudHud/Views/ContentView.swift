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

// MARK: - ContentView

@MainActor
struct ContentView: View {

	// NOTE: As a workaround until Toursprung prvides us with an endpoint that services this file
	private let styleURL = Bundle.main.url(forResource: "Terrain", withExtension: "json")! // swiftlint:disable:this force_unwrapping
	private let locationManager = Location()

	@StateObject private var searchViewStore: SearchViewStore
	@StateObject private var mapStore = MapStore()
	@State private var showUserLocation: Bool = false
	@State var sheetSize: CGSize = .zero

	var body: some View {
		if #available(iOS 17.0, *) {
			return MapView(styleURL: self.styleURL, camera: self.$mapStore.camera) {
				let pointSource = self.mapStore.mapItemStatus.points

				CircleStyleLayer(identifier: "simple-circles", source: pointSource)
					.radius(16)
					.color(.systemRed)
					.strokeWidth(2)
					.strokeColor(.white)
				SymbolStyleLayer(identifier: "simple-symbols", source: pointSource)
					.iconImage(UIImage(systemSymbol: .mappin).withRenderingMode(.alwaysTemplate))
					.iconColor(.white)
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
				self.showUserLocation = self.locationManager.authorizationStatus == .authorizedWhenInUse
			}
			.ignoresSafeArea()
			.safeAreaInset(edge: .top, alignment: .center) {
				VStack {
					CategoriesBannerView(catagoryBannerData: CatagoryBannerData.cateoryBannerFakeDate, searchStore: self.searchViewStore)
					Spacer()
				}
				.presentationBackground(.thinMaterial)
				.padding()
			}
			.safeAreaInset(edge: .bottom, alignment: .trailing) {
				VStack(alignment: .trailing) {
					CurrentLocationButton(camera: self.$mapStore.camera)
					ProviderButton(searchViewStore: self.searchViewStore)
				}
				.opacity(sheetSize.height > 200 ? 0 : 1)
				.padding(.trailing)
			}
			.safeAreaPadding(.bottom, sheetSize.height)
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
					.presentationDragIndicator(.hidden)
					.overlay {
						GeometryReader { geometry in
							Color.clear.preference(key: SizePreferenceKey.self, value: geometry.size)
						}
					}
					.onPreferenceChange(SizePreferenceKey.self) { value in
						withAnimation {
							sheetSize = value
						}
					}
			}
		} else {
			return Text("Available only on ios 17 or newer")
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
	static let small: PresentationDetent = .height(80)
	static let third: PresentationDetent = .fraction(0.33)
}

extension CLLocationCoordinate2D {
	static let riyadh = CLLocationCoordinate2D(latitude: 24.71, longitude: 46.67)
}

// MARK: - SizePreferenceKey

struct SizePreferenceKey: PreferenceKey {
	static var defaultValue: CGSize = .zero

	// MARK: - Internal

	static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
		value = nextValue()
	}
}

#Preview {
	return ContentView(searchViewStore: .preview)
}
