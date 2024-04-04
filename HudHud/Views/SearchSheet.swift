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
import OSLog
import POIService
import SwiftLocation
import SwiftUI
import ToursprungPOI

// MARK: - SearchSheet

struct SearchSheet: View {

	private var cancelables: Set<AnyCancellable> = []

	@ObservedObject var mapStore: MapStore
	@ObservedObject var searchStore: SearchViewStore
	@FocusState private var searchIsFocused: Bool

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
			if !self.searchStore.searchText.isEmpty {
				if self.searchStore.isSearching {
					List {
						ForEach(SearchSheet.fakeData.indices, id: \.self) { item in
							Button(action: {},
								   label: {
								   	SearchSheet.fakeData[item]
								   		.frame(maxWidth: .infinity)
								   })
								   .redacted(reason: .placeholder)
								   .disabled(true)
						}
						.listRowSeparator(.hidden)
						.listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 2, trailing: 8))
					}
					.listStyle(.plain)
				} else {
					List(self.$mapStore.mapItemStatus.mapItems, id: \.self) { item in
						Button(action: {
							self.searchIsFocused = false
							self.searchStore.selectedDetent = .small
							switch item.wrappedValue.provider {
							case .toursprung:
								self.mapStore.mapItemStatus = MapItemsStatus(selectedItem: item.wrappedValue.poi, mapItems: self.mapStore.mapItemStatus.mapItems)
							case .appleCompletion:
								self.searchStore.selectedDetent = .medium
								self.searchIsFocused = false
								Task {
									let items = try await self.searchStore.resolve(prediction: item.wrappedValue)
									if let firstResult = items.first, items.count == 1 {
										self.mapStore.mapItemStatus = MapItemsStatus(selectedItem: firstResult.poi, mapItems: items)
									} else {
										self.mapStore.mapItemStatus = MapItemsStatus(selectedItem: nil, mapItems: items)
									}
								}
							case .appleMapItem:
								self.mapStore.mapItemStatus = MapItemsStatus(selectedItem: item.wrappedValue.poi, mapItems: self.mapStore.mapItemStatus.mapItems)
							}
						}, label: {
							SearchResultItem(prediction: item.wrappedValue, searchViewStore: self.searchStore)
								.frame(maxWidth: .infinity)
								.redacted(reason: self.searchStore.isSearching ? .placeholder : [])
						})
						.disabled(self.searchStore.isSearching)
						.listRowSeparator(.hidden)
						.listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 2, trailing: 8))
					}
					.listStyle(.plain)
				}
			} else {
				List {
					SearchSectionView(title: "Favorites") {
						FavoriteCategoriesView()
					}

					.listRowSeparator(.hidden)
				}
				.listStyle(.plain)
			}
		}
		.sheet(item: self.$mapStore.mapItemStatus.selectedItem) {
			self.searchStore.selectedDetent = .medium
		} content: { item in

			POIDetailSheet(poi: item) { routes in
				Logger.searchView.info("Start item \(item)")
				self.route = routes.routes.first
			} onMore: {
				Logger.searchView.info("more item \(item))")
			}
			.presentationDetents([.third, .large])
			.presentationBackgroundInteraction(
				.enabled(upThrough: .third)
			)
			.interactiveDismissDisabled()
			.ignoresSafeArea()
			.fullScreenCover(item: self.$route) { route in
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
	}

	// MARK: - Internal
}

#Preview {
	let searchViewStore: SearchViewStore = .preview
	return SearchSheet(mapStore: searchViewStore.mapStore, searchStore: searchViewStore)
}

extension Route: Identifiable {}

extension SearchSheet {
	static var fakeData = [
		SearchResultItem(prediction: Row(toursprung: .starbucks), searchViewStore: .preview),
		SearchResultItem(prediction: Row(toursprung: .supermarket), searchViewStore: .preview),
		SearchResultItem(prediction: Row(toursprung: .pharmacy), searchViewStore: .preview),
		SearchResultItem(prediction: Row(toursprung: .artwork), searchViewStore: .preview),
		SearchResultItem(prediction: Row(toursprung: .ketchup), searchViewStore: .preview),
		SearchResultItem(prediction: Row(toursprung: .publicPlace), searchViewStore: .preview)
	]
}
