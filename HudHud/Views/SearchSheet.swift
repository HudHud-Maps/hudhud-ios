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

	@ObservedObject var viewModel: SearchViewStore
	@FocusState private var searchIsFocused: Bool
	@State private var detailSheetShown: Bool = false

	@Binding var camera: MapViewCamera
//	@Binding var selectedPOI: POI?
	@Binding var selectedDetent: PresentationDetent

	var body: some View {
		return VStack {
			HStack {
				Image(systemSymbol: .magnifyingglass)
					.foregroundStyle(.tertiary)
					.padding(.leading, 8)
				TextField("Search", text: self.$viewModel.searchText)
					.focused($searchIsFocused)
					.padding(.vertical, 10)
					.padding(.horizontal, 0)
					.cornerRadius(8)
					.autocorrectionDisabled()
					.overlay(
						HStack {
							Spacer()
							if !self.viewModel.searchText.isEmpty {
								Button(action: {
									self.viewModel.searchText = ""
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
			.background(.white)
			.cornerRadius(8)

			List(self.$viewModel.mapItemsState.mapItems, id: \.self) { item in
				Button(action: {
					switch item.wrappedValue.provider {
					case .toursprung:
						self.show(row: item.wrappedValue)
					case .appleCompletion:
						self.selectedDetent = .large
						self.searchIsFocused = false
						Task {
							let items = try await self.viewModel.resolve(prediction: item.wrappedValue)
							if let firstResult = items.first, items.count == 1 {
								self.show(row: firstResult)
							} else {
								self.viewModel.mapItemsState.mapItems = items
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
		.sheet(item: .constant(self.viewModel.mapItemsState.selectedItem)) {
			self.selectedDetent = .medium
		} content: { _ in
			POIDetailSheet(poi: .constant(self.viewModel.mapItemsState.selectedItem), isShown: $detailSheetShown) {
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

	func show(row: Row) {
		self.searchIsFocused = false
		self.selectedDetent = .small
		if let coordinate = row.coordinate {
			self.camera = .center(coordinate, zoom: 16)
		}
//		self.selectedPOI = row.poi
		
		let index = self.viewModel.mapItemsState.mapItems.firstIndex(of: row)
		self.viewModel.mapItemsState.selectedIndex = index
		self.detailSheetShown = true
	}
}

#Preview {
	let sheet = SearchSheet(viewModel: .init(mode: .preview),
							camera: .constant(.center(.riyadh, zoom: 12)),
							selectedDetent: .constant(.medium))
	return sheet
}
