//
//  SearchSheet.swift
//  HudHud
//
//  Created by Patrick Kladek on 01.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

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

	@ObservedObject var mapStore: MapStore
	@ObservedObject var searchStore: SearchViewStore
	@FocusState private var searchIsFocused: Bool

	@AppStorage("RecentViewedItem") var recentViewedItem = [ResolvedItem]()

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
					List(self.mapStore.displayableItems) { item in
						Button(action: {
							Task {
								let resolvedItems = try await item.execute(in: self.searchStore.apple)

								if resolvedItems.count == 1, let firstItem = resolvedItems.first {
									let resolvedItem = firstItem.innerModel as? ResolvedItem
									self.mapStore.selectedItem = resolvedItem
								} else {
									self.mapStore.displayableItems = resolvedItems
								}
							}
							self.searchStore.selectedDetent = .medium
							self.searchIsFocused = false
						}, label: {
							SearchResultItem(prediction: item, searchViewStore: self.searchStore)
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
					.listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 2, trailing: 8))
					SearchSectionView(title: "Recents") {
						ForEach(self.recentViewedItem) { item in
							RecentSearchResultsView(item: item, mapStore: self.mapStore, searchStore: self.searchStore)
						}
					}
					.listRowSeparator(.hidden)
					.listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 2, trailing: 8))
					.padding(.top)
				}
				.listStyle(.plain)
			}
		}
		.sheet(item: self.$mapStore.selectedItem) {
			// Dismiss callback
			self.searchStore.selectedDetent = .medium
		} content: { item in
			POIDetailSheet(item: item, onStart: { calculation in
				Logger.searchView.info("Start item \(item.title)")
				self.mapStore.route = calculation.routes.first
				self.mapStore.displayableItems = [AnyDisplayableAsRow(item)]
			}, onMore: {
				Logger.searchView.info("more item \(item.title))")
			})
			.presentationDetents([.third, .large])
			.presentationBackgroundInteraction(
				.enabled(upThrough: .third)
			)
			.interactiveDismissDisabled()
			.ignoresSafeArea()
			.onAppear {
				// Store POI
				// self.storeRecentPOI(poi: item)
			}
		}
	}

	// MARK: - Lifecycle

	init(mapStore: MapStore, searchStore: SearchViewStore) {
		self.mapStore = mapStore
		self.searchStore = searchStore
		self.searchIsFocused = false
	}

	// MARK: - Internal

//	func storeRecentPOI(poi: POI) {
//		withAnimation {
//			if self.recentViewedPOIs.count > 9 {
//				self.recentViewedPOIs.removeFirst()
//			}
//			if !self.recentViewedPOIs.contains(poi) {
//				self.recentViewedPOIs.append(poi)
//			}
//		}
//	}

}

#Preview {
	let searchViewStore: SearchViewStore = .storeSetUpForPreviewing
	return SearchSheet(mapStore: searchViewStore.mapStore, searchStore: searchViewStore)
}

extension Route: Identifiable {}

extension SearchSheet {
	static var fakeData = [
		SearchResultItem(prediction: PredictionItem(poi: .starbucks), searchViewStore: .storeSetUpForPreviewing),
		SearchResultItem(prediction: PredictionItem(poi: .supermarket), searchViewStore: .storeSetUpForPreviewing),
		SearchResultItem(prediction: PredictionItem(poi: .pharmacy), searchViewStore: .storeSetUpForPreviewing),
		SearchResultItem(prediction: PredictionItem(poi: .artwork), searchViewStore: .storeSetUpForPreviewing),
		SearchResultItem(prediction: PredictionItem(poi: .ketchup), searchViewStore: .storeSetUpForPreviewing),
		SearchResultItem(prediction: PredictionItem(poi: .publicPlace), searchViewStore: .storeSetUpForPreviewing)
	]
}

extension PredictionItem {

	init(poi: POI) {
		self.init(id: poi.id,
				  title: poi.title,
				  subtitle: poi.subtitle,
				  icon: poi.icon,
				  type: .appleResolved)
	}
}

// MARK: - RawRepresentable + RawRepresentable

extension [ResolvedItem]: RawRepresentable {
	public init?(rawValue: String) {
		guard let data = rawValue.data(using: .utf8),
			  let result = try? JSONDecoder()
			  	.decode([ResolvedItem].self, from: data) else {
			return nil
		}
		self = result
	}

	public var rawValue: String {
		guard let data = try? JSONEncoder().encode(self),
			  let result = String(data: data, encoding: .utf8) else {
			return "[]"
		}
		return result
	}
}
