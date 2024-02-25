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
import MapLibreSwiftUI
import POIService
import SwiftUI
import ToursprungPOI

struct SearchSheet: View {

	private var cancelables: Set<AnyCancellable> = []

	@ObservedObject var mapStore: MapStore
	@ObservedObject var searchStore: SearchViewStore
	@FocusState private var searchIsFocused: Bool
	@State private var detailSheetShown: Bool = false

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
					.cornerRadius(8)
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
			.padding(.horizontal, 12)
			.padding(.vertical, 8)
			.background(.background)
			.cornerRadius(8)

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
		// I have never used .constant in my years of SwiftUI... If you are about to use it you are probably doing something wrong.
		// sheets use bindings because its a two way relationship - if the sheet is dismissed it will clear what is in
		.sheet(item: self.$mapStore.mapItemStatus.selectedItem) {
			self.searchStore.selectedDetent = .medium
		} content: { item in
			POIDetailSheet(poi: item) {
				print("start")
			} onMore: {
				print("more")
			}
			.presentationDetents([.third, .large])
			.presentationBackgroundInteraction(
				.enabled(upThrough: .third)
			)
			.interactiveDismissDisabled()
			.ignoresSafeArea()
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

//	init(mapStore: Binding<MapStore>, searchStore: SearchViewStore, camera: Binding<MapViewCamera>, selectedDetent: Binding<PresentationDetent>) {
//		self._mapStore = mapStore
//		self.searchStore = searchStore
//		self._camera = camera
//		self._selectedDetent = selectedDetent
//
//		self.searchStore.$items.sink { items in
//			print("Changed: \(items)")
//			self.mapStore.mapItemStore.mapItems = items
//		}.store(in: &self.cancelables)
//	}

	// MARK: - Internal

	func show(row: Row) {
		self.searchIsFocused = false
		self.searchStore.selectedDetent = .small

//		// anything to do with camera updates should not be in the SearchSheet code - what if items change while the searchsheet is not showing? MapStore or MapView will need to manage the camera
//		if let coordinate = row.coordinate {
//			self.mapStore.camera = .center(coordinate, zoom: 16)
//		}
		self.mapStore.mapItemStatus.selectedItem = row.poi
		self.detailSheetShown = true
	}
}

#Preview {
	let sheet = SearchSheet(mapStore: .init(),
							searchStore: .init(mode: .preview))
	return sheet
}
