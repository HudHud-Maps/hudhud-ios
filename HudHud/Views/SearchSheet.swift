//
//  SearchSheet.swift
//  HudHud
//
//  Created by Patrick Kladek on 01.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import ApplePOI
import Foundation
import MapLibreSwiftUI
import POIService
import SwiftUI
import ToursprungPOI

struct SearchSheet: View {

	@ObservedObject var viewStore: SearchViewStore
	@FocusState private var searchIsFocused: Bool
	@State private var detailSheetShown: Bool = false

	@Binding var camera: MapViewCamera
	@Binding var selectedDetent: PresentationDetent

	var body: some View {
		return VStack {
			HStack {
				Image(systemSymbol: .magnifyingglass)
					.foregroundStyle(.tertiary)
					.padding(.leading, 8)
				TextField("Search", text: self.$viewStore.searchText)
					.focused(self.$searchIsFocused)
					.padding(.vertical, 10)
					.padding(.horizontal, 0)
					.cornerRadius(8)
					.autocorrectionDisabled()
					.overlay(
						HStack {
							Spacer()
							if !self.viewStore.searchText.isEmpty {
								Button(action: {
									self.viewStore.searchText = ""
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

			List(self.$viewStore.mapItemsState.mapItems, id: \.self) { item in
				Button(action: {
					switch item.wrappedValue.provider {
					case .toursprung:
						self.show(row: item.wrappedValue)
					case .appleCompletion:
						self.selectedDetent = .large
						self.searchIsFocused = false
						Task {
							let items = try await self.viewStore.resolve(prediction: item.wrappedValue)
							if let firstResult = items.first, items.count == 1 {
								self.show(row: firstResult)
							} else {
								self.viewStore.mapItemsState.mapItems = items
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
		.sheet(item: .constant(self.viewStore.mapItemsState.selectedItem)) {
			self.selectedDetent = .medium
		} content: { _ in
			POIDetailSheet(poi: .constant(self.viewStore.mapItemsState.selectedItem), isShown: self.$detailSheetShown) {
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

	// MARK: - Internal

	func show(row: Row) {
		self.searchIsFocused = false
		self.selectedDetent = .small
		if let coordinate = row.coordinate {
			self.camera = .center(coordinate, zoom: 16)
		}
		self.viewStore.mapItemsState.selectedItem = row.poi
		self.detailSheetShown = true
	}
}

#Preview {
	let sheet = SearchSheet(viewStore: .init(mode: .preview),
							camera: .constant(.center(.riyadh, zoom: 12)),
							selectedDetent: .constant(.medium))
	return sheet
}
