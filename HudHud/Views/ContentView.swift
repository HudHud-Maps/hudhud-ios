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
import OSLog
import POIService
import SFSafeSymbols
import SimpleToast
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
	@StateObject private var mapStore: MapStore
	@State private var showUserLocation: Bool = false
	@StateObject var notificationQueue: NotificationQueue = .init()
	@State private var showMapLayer: Bool = false
	@State var sheetSize: CGSize = .zero
	@State var didTryToZoomOnUsersLocation = false

	var body: some View {
		MapView(styleURL: self.styleURL, camera: self.$mapStore.camera) {
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
		/*
		 .onTapMapGesture(onTapChanged: { context, mapView in
		 	guard context.state == .ended else {
		 		return
		 	}

		 	let point = context.point
		 	let width = 16.0 * 2.0 // CircleStyleLayer Radius
		 	let rect = CGRect(x: point.x - width / 2.0, y: point.y - width / 2.0, width: width, height: width)
		 	let features = mapView.visibleFeatures(in: rect, styleLayerIdentifiers: ["simple-circles"])

		 	// Pick the first feature (which may be a port or a cluster), ideally selecting
		 	// the one nearest nearest one to the touch point.
		 	guard let feature = features.first,
		 		  let placeID = feature.attribute(forKey: "poi_id") as? String else
		 	{
		 		// user tapped nothing - deselect
		 		self.searchViewStore.mapStore.mapItemStatus.selectedItem = nil
		 		return
		 	}

		 	let mapItems = self.searchViewStore.mapStore.mapItemStatus.mapItems
		 	let poi = mapItems.first { row in
		 		row.poi?.id == placeID
		 	}?.poi

		 	if let poi {
		 		self.searchViewStore.mapStore.mapItemStatus.selectedItem = poi
		 	}
		 })
		  */
		.unsafeMapViewModifier { mapView in
			mapView.showsUserLocation = self.showUserLocation
		}
		.task {
			for await event in await self.locationManager.startMonitoringAuthorization() {
				Logger.searchView.debug("Authorization status did change: \(event.authorizationStatus, align: .left(columns: 10))")
				self.showUserLocation = event.authorizationStatus.allowed
			}
		}
		.task {
			self.showUserLocation = self.locationManager.authorizationStatus.allowed
			Logger.searchView.debug("Authorization status authorizedAllowed")
		}
		.task {
			do {
				guard self.didTryToZoomOnUsersLocation == false else {
					return
				}
				self.didTryToZoomOnUsersLocation = true
				self.locationManager.accuracy = .threeKilometers
				let userLocation = try await locationManager.requestLocation()
				var coordinates: CLLocationCoordinate2D? = userLocation.location?.coordinate
				if coordinates == nil {
					// fall back to any location that was found, even if bad
					// accuracy
					coordinates = self.locationManager.lastLocation?.coordinate
				}
				guard let coordinates else {
					print("Could not determine user location, will not zoom...")
					return
				}

				self.mapStore.camera = MapViewCamera.center(coordinates, zoom: 16)

			} catch {
				print("location error: \(error)")
			}
		}
		.ignoresSafeArea()
		.safeAreaInset(edge: .top, alignment: .center) {
			CategoriesBannerView(catagoryBannerData: CatagoryBannerData.cateoryBannerFakeDate, searchStore: self.searchViewStore)
				.presentationBackground(.thinMaterial)
		}
		.safeAreaInset(edge: .bottom) {
			HStack(alignment: .bottom) {
				MapButtonsView(mapButtonsData: [
					MapButtonData(sfSymbol: .icon(.map)) {
						self.showMapLayer.toggle()
					},
					MapButtonData(sfSymbol: MapButtonData.buttonIcon(for: self.searchViewStore.mode)) {
						switch self.searchViewStore.mode {
						case let .live(provider):
							self.searchViewStore.mode = .live(provider: provider.next())
							Logger.searchView.info("Map Mode live")
						case .preview:
							self.searchViewStore.mode = .live(provider: .toursprung)
							Logger.searchView.info("Map Mode toursprung")
						}
					},
					MapButtonData(sfSymbol: .icon(.cube)) {
						print("Location button tapped")
					}
				])
				Spacer()
				VStack(alignment: .trailing) {
					CurrentLocationButton(camera: self.$mapStore.camera)
				}
			}
			.opacity(self.sheetSize.height > 500 ? 0 : 1)
			.padding(.horizontal)
		}
		.backport.safeAreaPadding(.bottom, self.sheetSize.height + 8)
		.sheet(isPresented: self.$mapStore.searchShown) {
			SearchSheet(mapStore: self.mapStore,
						searchStore: self.searchViewStore)
				.frame(minWidth: 320)
				.presentationCornerRadius(21)
				.presentationDetents([.small, .medium, .large], selection: self.$searchViewStore.selectedDetent)
				.presentationBackgroundInteraction(
					.enabled(upThrough: .large)
				)
				.interactiveDismissDisabled()
				.ignoresSafeArea()
				.presentationCompactAdaptation(.sheet)
				.overlay {
					GeometryReader { geometry in
						Color.clear.preference(key: SizePreferenceKey.self, value: geometry.size)
					}
				}
				.onPreferenceChange(SizePreferenceKey.self) { value in
					withAnimation(.easeOut) {
						self.sheetSize = value
					}
				}
				.sheet(isPresented: self.$showMapLayer) {
					VStack(alignment: .center, spacing: 30) {
						HStack(alignment: .center) {
							Spacer()
							Text("Layers")
								.foregroundStyle(.primary)
							Spacer()
							Button {
								self.showMapLayer.toggle()
							} label: {
								Image(systemSymbol: .xmark)
									.foregroundColor(.secondary)
							}
						}
						.padding(.horizontal, 30)
						MainLayersView(mapLayerData: MapLayersData.getLayers())
							.presentationCornerRadius(21)
							.presentationDetents([.medium])
					}
				}
		}
		.environmentObject(self.notificationQueue)
		.simpleToast(item: self.$notificationQueue.currentNotification, options: .notification, onDismiss: {
			self.notificationQueue.removeFirst()
		}, content: {
			if let notification = self.notificationQueue.currentNotification {
				NotificationBanner(notification: notification)
					.padding(.horizontal, 8)
			}
		})
	}

	// MARK: - Lifecycle

	@MainActor
	init(searchViewStore: SearchViewStore) {
		self._searchViewStore = .init(wrappedValue: searchViewStore)
		self._mapStore = .init(wrappedValue: searchViewStore.mapStore)
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

extension SimpleToastOptions {
	static let notification = SimpleToastOptions(alignment: .top, hideAfter: 5, modifierType: .slide)
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
	ContentView(searchViewStore: .preview)
}

#Preview("Touch Testing") {
	let store: SearchViewStore = .preview
	store.searchText = "shops"
	store.selectedDetent = .medium
	return ContentView(searchViewStore: store)
}
