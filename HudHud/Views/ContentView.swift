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

	@StateObject private var notificationQueue = NotificationQueue()

	@ObservedObject private var motionViewModel: MotionViewModel
	@ObservedObject private var searchViewStore: SearchViewStore
	@ObservedObject private var mapStore: MapStore

	@State private var showUserLocation: Bool = false
	@State private var showMapLayer: Bool = false
	@State private var sheetSize: CGSize = .zero
	@State private var didTryToZoomOnUsersLocation = false

	var body: some View {
		MapView(styleURL: self.styleURL, camera: self.$mapStore.camera) {
			let pointSource = self.mapStore.points

			CircleStyleLayer(identifier: "simple-circles", source: pointSource)
				.radius(16)
				.color(.systemRed)
				.strokeWidth(2)
				.strokeColor(.white)
			SymbolStyleLayer(identifier: "simple-symbols", source: pointSource)
				.iconImage(UIImage(systemSymbol: .mappin).withRenderingMode(.alwaysTemplate))
				.iconColor(.white)
				.iconRotation(45)

			SymbolStyleLayer(identifier: "street-view-symbols", source: self.mapStore.streetViewSource)
				.iconImage(UIImage.lookAroundPin)
				.iconRotation(featurePropertyNamed: "heading")
		}
		.onTapMapGesture(on: ["simple-circles"], onTapChanged: { _, features in
			// Pick the first feature (which may be a port or a cluster), ideally selecting
			// the one nearest nearest one to the touch point.
			guard let feature = features.first,
				  let placeID = feature.attribute(forKey: "poi_id") as? String else {
				// user tapped nothing - deselect
				Logger.mapInteraction.debug("Tapped nothing - setting to nil...")
				self.searchViewStore.mapStore.selectedItem = nil
				return
			}

			let mapItems = self.searchViewStore.mapStore.mapItems
			let poi = mapItems.first { row in
				row.poi?.id == placeID
			}?.poi

			if let poi {
				Logger.mapInteraction.debug("setting poi")
				self.searchViewStore.mapStore.selectedItem = poi
			} else {
				Logger.mapInteraction.warning("User tapped a feature but it had no POI")
			}
		})
		.unsafeMapViewModifier { mapView in
			mapView.showsUserLocation = self.showUserLocation && self.mapStore.streetView == .disabled
		}
		.task {
			for await event in await Location.forSingleRequestUsage.startMonitoringAuthorization() {
				Logger.searchView.debug("Authorization status did change: \(event.authorizationStatus, align: .left(columns: 10))")
				self.showUserLocation = event.authorizationStatus.allowed
			}
		}
		.task {
			self.showUserLocation = Location.forSingleRequestUsage.authorizationStatus.allowed
			Logger.searchView.debug("Authorization status authorizedAllowed")
		}
		.task {
			do {
				guard self.didTryToZoomOnUsersLocation == false else {
					return
				}
				self.didTryToZoomOnUsersLocation = true
				let userLocation = try await Location.forSingleRequestUsage.requestLocation()
				var coordinates: CLLocationCoordinate2D? = userLocation.location?.coordinate
				if coordinates == nil {
					// fall back to any location that was found, even if bad
					// accuracy
					coordinates = Location.forSingleRequestUsage.lastLocation?.coordinate
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
			if case .point = self.mapStore.streetView {
				StreetView(viewModel: self.motionViewModel)
					.onAppear {
						Task {
							let userLocation = try await Location.forSingleRequestUsage.requestLocation()
							guard let location = userLocation.location else { return }

							self.motionViewModel.coordinate = location.coordinate
							self.mapStore.streetView = .point(StreetViewPoint(location: location.coordinate, heading: location.course))
						}
					}
					.onDisappear {
						self.mapStore.streetView = .disabled
					}
			} else {
				CategoriesBannerView(catagoryBannerData: CatagoryBannerData.cateoryBannerFakeData, searchStore: self.searchViewStore)
					.presentationBackground(.thinMaterial)
			}
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
					MapButtonData(sfSymbol: .icon(self.mapStore.streetView == .disabled ? .pano : .panoFill)) {
						if self.mapStore.streetView == .disabled {
							Task {
								self.mapStore.streetView = .requestedCurrentLocation
								let location = try await Location.forSingleRequestUsage.requestLocation()
								guard let location = location.location else { return }

								print("set new streetViewPoint")
								let point = StreetViewPoint(location: location.coordinate, heading: location.course)
								self.mapStore.streetView = .point(point)

								/*
								  // use Task.sleep for such things in a Task context
								 DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
								 	self.motionViewModel.coordinate = .image2
								 }
								  */
							}
						} else {
							self.mapStore.streetView = .disabled
						}
					},
					MapButtonData(sfSymbol: .icon(.cube)) {
						print("3D Map toggle tapped")
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
	init(searchStore: SearchViewStore) {
		self.searchViewStore = searchStore
		self.mapStore = searchStore.mapStore
		self.motionViewModel = searchStore.mapStore.motionViewModel
	}
}

// MARK: - SimpleToastOptions

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
	let searchViewStore: SearchViewStore = .storeSetUpForPreviewing
	return ContentView(searchStore: searchViewStore)
}

#Preview("Touch Testing") {
	let store: SearchViewStore = .storeSetUpForPreviewing
	store.searchText = "shops"
	store.selectedDetent = .medium
	return ContentView(searchStore: store)
}
