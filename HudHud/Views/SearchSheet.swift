//
//  SearchSheet.swift
//  HudHud
//
//  Created by Patrick Kladek on 01.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import ApplePOI
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

	@Environment(\.openURL) private var openURL
	@State private var isPresentWebView = false
	@AppStorage("RecentViewedPOIs") var recentViewedPOIs = RecentViewedPOIs()

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
					List(self.$mapStore.mapItems, id: \.self) { item in
						Button(action: {
							self.searchIsFocused = false
							switch item.wrappedValue.provider {
							case .toursprung:
								self.mapStore.selectedItem = item.wrappedValue.poi
							case .appleCompletion:
								self.searchIsFocused = false
								Task {
									let items = try await self.searchStore.resolve(prediction: item.wrappedValue)
									if let firstResult = items.first, items.count == 1 {
										self.mapStore.selectedItem = firstResult.poi
										self.mapStore.mapItems = items
									} else {
										self.mapStore.selectedItem = nil
										self.mapStore.mapItems = items
									}
								}
							case .appleMapItem:
								self.mapStore.selectedItem = item.wrappedValue.poi
							}
							self.searchStore.updateSheetDetent()
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
					.listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 2, trailing: 8))
					SearchSectionView(title: "Recents") {
						ForEach(self.searchStore.recentViewedPOIs, id: \.self) { pois in
							RecentSearchResultsView(poi: pois, mapStore: self.mapStore, searchStore: self.searchStore)
						}
					}

					.listRowSeparator(.hidden)
					.listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 2, trailing: 8))
					.padding(.top)
				}
				.listStyle(.plain)
			}
		}
		.backport.sheet(item: self.$mapStore.selectedItem) {
			self.searchStore.selectedDetent = .medium
		} content: { item in
			POIDetailSheet(poi: item) { routes in
				Logger.searchView.info("Start item \(item)")
				self.searchStore.selectedDetent = .small
				self.mapStore.routes = routes
				self.mapStore.mapItems = [Row(toursprung: item)]
				if let location = routes.waypoints.first {
					self.mapStore.waypoints = [.myLocation(location), .poi(item)]
				}

			} onMore: { action in
				switch action {
				case .phone:
					// Perform phone action
					if let phone = item.phone, let url = URL(string: "tel://\(phone)") {
						self.openURL(url)
					}
					Logger.searchView.info("Item phone \(item.phone ?? "nil")")
				case .website:
					// Perform website action
					self.isPresentWebView = true
					Logger.searchView.info("Item website \(item.website?.absoluteString ?? "")")
				case .moreInfo:
					// Perform more info action
					Logger.searchView.info("more item \(item))")
				}
			} onDismiss: {
				self.mapStore.selectedItem = nil
			}
			.fullScreenCover(isPresented: self.$isPresentWebView) {
				if let website = item.website {
					SafariWebView(url: website)
						.ignoresSafeArea()
				}
			}
			.presentationDetents([.third, .large])
			.presentationBackgroundInteraction(
				.enabled(upThrough: .third)
			)
			.interactiveDismissDisabled()
			.ignoresSafeArea()
			.onAppear {
				// Store POI
				self.storeRecentPOI(poi: item)
				// update sheet
				self.searchStore.updateSheetDetent()
			}
			.onChange(of: self.mapStore.selectedItem) { _ in
				self.searchStore.updateSheetDetent()
			}
			.onChange(of: self.searchStore.searchText) { _ in
				self.searchStore.updateSheetDetent()
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

	func storeRecentPOI(poi: POI) {
		withAnimation {
			if self.searchStore.recentViewedPOIs.count > 9 {
				self.searchStore.recentViewedPOIs.removeFirst()
			}
			if !self.searchStore.recentViewedPOIs.contains(poi) {
				self.searchStore.recentViewedPOIs.append(poi)
			}
		}
	}

	func dismissSheet() {
		self.mapStore.selectedItem = nil // Set selectedItem to nil to dismiss the sheet
	}

}

extension Route: Identifiable {}

extension SearchSheet {
	static var fakeData = [
		SearchResultItem(prediction: Row(toursprung: .starbucks), searchViewStore: .storeSetUpForPreviewing),
		SearchResultItem(prediction: Row(toursprung: .supermarket), searchViewStore: .storeSetUpForPreviewing),
		SearchResultItem(prediction: Row(toursprung: .pharmacy), searchViewStore: .storeSetUpForPreviewing),
		SearchResultItem(prediction: Row(toursprung: .artwork), searchViewStore: .storeSetUpForPreviewing),
		SearchResultItem(prediction: Row(toursprung: .ketchup), searchViewStore: .storeSetUpForPreviewing),
		SearchResultItem(prediction: Row(toursprung: .publicPlace), searchViewStore: .storeSetUpForPreviewing)
	]
}

public typealias RecentViewedPOIs = [POI]

// MARK: - RawRepresentable

extension RecentViewedPOIs: RawRepresentable {
	public init?(rawValue: String) {
		guard let data = rawValue.data(using: .utf8),
			  let result = try? JSONDecoder()
			  	.decode(RecentViewedPOIs.self, from: data) else {
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

#Preview {
	let searchViewStore: SearchViewStore = .storeSetUpForPreviewing
	return SearchSheet(mapStore: searchViewStore.mapStore, searchStore: searchViewStore)
}
