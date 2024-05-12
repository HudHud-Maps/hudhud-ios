//
//  ContentView.swift
//  HudHud
//
//  Created by Patrick Kladek on 29.01.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import MapboxDirections
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import OSLog
import POIService
import SFSafeSymbols
import SimpleToast
import SwiftLocation
import SwiftUI

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

	@State var offsetY: CGFloat = 0
	@State var selectedDetent: PresentationDetent = .medium

	var body: some View {
		MapView(styleURL: self.styleURL, camera: self.$mapStore.camera) {
			// Display preview data as a polyline on the map
			if let route = self.mapStore.routes?.routes.first {
				let polylineSource = ShapeSource(identifier: MapSourceIdentifier.pedestrianPolyline) {
					MLNPolylineFeature(coordinates: route.coordinates ?? [])
				}

				// Add a polyline casing for a stroke effect
				LineStyleLayer(identifier: MapLayerIdentifier.routeLineCasing, source: polylineSource)
					.lineCap(.round)
					.lineJoin(.round)
					.lineColor(.white)
					.lineWidth(interpolatedBy: .zoomLevel,
							   curveType: .linear,
							   parameters: NSExpression(forConstantValue: 1.5),
							   stops: NSExpression(forConstantValue: [18: 14, 20: 26]))

				// Add an inner (blue) polyline
				LineStyleLayer(identifier: MapLayerIdentifier.routeLineInner, source: polylineSource)
					.lineCap(.round)
					.lineJoin(.round)
					.lineColor(.systemBlue)
					.lineWidth(interpolatedBy: .zoomLevel,
							   curveType: .linear,
							   parameters: NSExpression(forConstantValue: 1.5),
							   stops: NSExpression(forConstantValue: [18: 11, 20: 18]))

				let routePoints = self.mapStore.routePoints

				CircleStyleLayer(identifier: MapLayerIdentifier.simpleCirclesRoute, source: routePoints)
					.radius(16)
					.color(.systemRed)
					.strokeWidth(2)
					.strokeColor(.white)
				SymbolStyleLayer(identifier: MapLayerIdentifier.simpleSymbolsRoute, source: routePoints)
					.iconImage(UIImage(systemSymbol: .mappin).withRenderingMode(.alwaysTemplate))
					.iconColor(.white)
			}
			let pointSource = self.mapStore.points

			// shows the clustered pins
			CircleStyleLayer(identifier: MapLayerIdentifier.simpleCirclesClustered, source: pointSource)
				.radius(16)
				.color(.systemRed)
				.strokeWidth(2)
				.strokeColor(.white)
				.predicate(NSPredicate(format: "cluster == YES"))
			SymbolStyleLayer(identifier: MapLayerIdentifier.simpleSymbolsClustered, source: pointSource)
				.textColor(.white)
				.text(expression: NSExpression(format: "CAST(point_count, 'NSString')"))
				.predicate(NSPredicate(format: "cluster == YES"))

			// shows the unclustered pins
			CircleStyleLayer(identifier: MapLayerIdentifier.simpleCircles, source: pointSource)
				.radius(16)
				.color(.systemRed)
				.strokeWidth(2)
				.strokeColor(.white)
				.predicate(NSPredicate(format: "cluster != YES"))
			SymbolStyleLayer(identifier: MapLayerIdentifier.simpleSymbols, source: pointSource)
				.iconImage(UIImage(systemSymbol: .mappin).withRenderingMode(.alwaysTemplate))
				.iconColor(.white)
				.predicate(NSPredicate(format: "cluster != YES"))

			SymbolStyleLayer(identifier: MapLayerIdentifier.streetViewSymbols, source: self.mapStore.streetViewSource)
				.iconImage(UIImage.lookAroundPin)
				.iconRotation(featurePropertyNamed: "heading")
		}
		.onTapMapGesture(on: [MapLayerIdentifier.simpleCircles], onTapChanged: { _, features in
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
			let poi = mapItems.first { poi in
				poi.id == placeID
			}

			if let poi {
				Logger.mapInteraction.debug("setting poi")
				self.searchViewStore.mapStore.selectedItem = poi
			} else {
				Logger.mapInteraction.warning("User tapped a feature but it's not a ResolvedItem")
			}
		})
		.unsafeMapViewModifier { mapView in
			mapView.showsUserLocation = self.showUserLocation && self.mapStore.streetView == .disabled
		}
		.onChange(of: self.mapStore.routes?.routes ?? []) { newRoute in
			if let route = newRoute.first, let coordinates = route.coordinates, !coordinates.isEmpty {
				if let camera = CameraState.boundingBox(from: coordinates) {
					self.mapStore.camera = camera
				}
			}
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
			if case .enabled = self.mapStore.streetView {
				StreetView(viewModel: self.motionViewModel, camera: self.$mapStore.camera)
			} else {
				if self.mapStore.routes == nil {
					CategoriesBannerView(catagoryBannerData: CatagoryBannerData.cateoryBannerFakeData, searchStore: self.searchViewStore)
						.presentationBackground(.thinMaterial)
				}
			}
		}
		.safeAreaInset(edge: .bottom) {
			if self.mapStore.routes == nil {
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
									self.motionViewModel.coordinate = location.coordinate
									if location.course > 0 {
										self.motionViewModel.position.heading = location.course
									}
									self.mapStore.streetView = .enabled
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
				.opacity(self.searchViewStore.selectedDetent == .small ? 1 : 0)
				.padding(.horizontal)
			}
		}
		.backport.buttonSafeArea(length: self.sheetSize)
		.backport.sheet(isPresented: self.$mapStore.searchShown) {
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

				.backport.sheet(isPresented: Binding<Bool>(
					get: { self.mapStore.routes != nil && self.mapStore.waypoints != nil },
					set: { _ in self.searchViewStore.searchType = .selectPOI }
				)) {
					NavigationSheetView(searchViewStore: self.searchViewStore, mapStore: self.mapStore)
						.presentationCornerRadius(21)
						.presentationDetents([.height(130), .medium, .large], selection: self.$selectedDetent)
						.presentationBackgroundInteraction(
							.enabled(upThrough: .medium)
						)
						.ignoresSafeArea()
						.interactiveDismissDisabled()
						.presentationCompactAdaptation(.sheet)
				}

				.sheet(isPresented: self.$showMapLayer) {
					VStack(alignment: .center, spacing: 25) {
						Spacer()
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
		self.mapStore.routes = searchStore.mapStore.routes
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

#Preview("Main Map") {
	let searchViewStore: SearchViewStore = .storeSetUpForPreviewing
	return ContentView(searchStore: searchViewStore)
}

#Preview("Touch Testing") {
	let store: SearchViewStore = .storeSetUpForPreviewing
	store.searchText = "shops"
	store.selectedDetent = .medium
	return ContentView(searchStore: store)
}
