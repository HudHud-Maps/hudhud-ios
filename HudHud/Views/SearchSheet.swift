//
//  SearchSheet.swift
//  HudHud
//
//  Created by Patrick Kladek on 01.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import ApplePOI
import Combine
import Foundation
import MapboxCoreNavigation
import MapboxDirections
import MapboxNavigation
import MapKit
import MapLibre
import MapLibreSwiftUI
import POIService
import SwiftUI
import ToursprungPOI

// MARK: - SearchSheet

struct SearchSheet: View {

	private var cancelables: Set<AnyCancellable> = []

	@ObservedObject var mapStore: MapStore
	@ObservedObject var searchStore: SearchViewStore
	@FocusState private var searchIsFocused: Bool
	@State private var detailSheetShown: Bool = false

	@State private var route: Route?

	var body: some View {
		return VStack {
			HStack {
				Image(systemSymbol: .magnifyingglass)
					.foregroundStyle(.tertiary)
					.padding(.leading, 8)
				TextField("Search", text: self.$searchStore.searchText)
					.focused(self.$searchIsFocused)
					.padding(.vertical, 10)
					.padding(.horizontal, 0)
					.autocorrectionDisabled()
					.overlay(
						HStack {
							Spacer()
							if !self.searchStore.searchText.isEmpty {
								Button(action: {
									self.searchStore.searchText = ""
								}, label: {
									Image(systemSymbol: .multiplyCircleFill)
										.foregroundColor(.gray)
										.padding(.vertical)
								})
							}
						}
						.padding(.horizontal, 8)
					)
					.padding(.horizontal, 10)
			}
			.background(.quinary)
			.cornerRadius(12)
			.padding()

			List(self.$mapStore.mapItemStatus.mapItems, id: \.self) { item in
				Button(action: {
					switch item.wrappedValue.provider {
					case .toursprung:
						self.show(row: item.wrappedValue)
					case .appleCompletion:
						self.searchStore.selectedDetent = .medium
						self.searchIsFocused = false
						Task {
							let items = try await self.searchStore.resolve(prediction: item.wrappedValue)
							if let firstResult = items.first, items.count == 1 {
								self.show(row: firstResult)
							} else {
								self.mapStore.mapItemStatus = MapItemsStatus(selectedItem: nil, mapItems: items)
							}
						}
					case .appleMapItem:
						self.show(row: item.wrappedValue)
					}
				}, label: {
					SearchResultItem(prediction: item.wrappedValue)
						.frame(maxWidth: .infinity)
				})
				.listRowSeparator(.hidden)
				.listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 2, trailing: 8))
			}
			.listStyle(.plain)
		}
		.sheet(item: self.$mapStore.mapItemStatus.selectedItem) {
			self.searchStore.selectedDetent = .medium
		} content: { item in
			POIDetailSheet(poi: item) {
				Task {
					print("start")

					let riyadh = CLLocation(latitude: 24.736054, longitude: 46.718932)
					let jeddah = CLLocation(latitude: 21.561995, longitude: 39.202545)
					let waypoints = [
						riyadh,
						jeddah
					].map { Waypoint(location: $0) }

					let options = NavigationRouteOptions(waypoints: waypoints, profileIdentifier: .automobileAvoidingTraffic)
					options.shapeFormat = .polyline6
					options.distanceMeasurementSystem = .metric
					options.attributeOptions = []

					let results = try await Toursprung.shared.calculate(options)
					self.route = results.routes.first
				}
			} onMore: {
				print("more")
			}
			.presentationDetents([.third, .large])
			.presentationBackgroundInteraction(
				.enabled(upThrough: .third)
			)
			.interactiveDismissDisabled()
			.ignoresSafeArea()
			.sheet(item: self.$route) { route in
				let styleURL = Bundle.main.url(forResource: "Terrain", withExtension: "json")! // swiftlint:disable:this force_unwrapping
				NavigationView(route: route, styleURL: styleURL)
			}
		}
	}

	// MARK: - Lifecycle

	init(mapStore: MapStore, searchStore: SearchViewStore) {
		self.cancelables = []
		self.mapStore = mapStore
		self.searchStore = searchStore
		self.searchIsFocused = false
		self.detailSheetShown = false
	}

	// MARK: - Internal

	func show(row: Row) {
		self.searchIsFocused = false
		self.searchStore.selectedDetent = .small
		self.mapStore.mapItemStatus.selectedItem = row.poi
		self.detailSheetShown = true
	}
}

#Preview {
	let sheet = SearchSheet(mapStore: .init(),
							searchStore: .init(mode: .preview))
	return sheet
}

extension Route: Identifiable {}
