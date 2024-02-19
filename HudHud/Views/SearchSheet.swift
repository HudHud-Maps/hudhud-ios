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

	@ObservedObject var viewModel: SearchViewModel
	@FocusState private var searchIsFocused: Bool
	@State private var detailSheetShown: Bool = false
	@State private var searchText = ""

	@Binding var camera: MapViewCamera
	@Binding var selectedPOI: POI?
	@Binding var selectedDetent: PresentationDetent

	var body: some View {
		VStack {
			HStack {
				Image(systemSymbol: .magnifyingglass)
					.foregroundStyle(.tertiary)
					.padding(.leading, 8)
				TextField("Search", text: $searchText)
					.focused($searchIsFocused)
					.padding(.vertical, 10)
					.padding(.horizontal, 0)
					.cornerRadius(8)
					.autocorrectionDisabled()
					.overlay(
						HStack {
							Spacer()
							if !self.searchText.isEmpty {
								Button(action: {
									self.searchText = ""
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

			List(self.viewModel.items, id: \.self) { item in
				Button(action: {
					switch item.provider {
					case .toursprung:
						self.searchIsFocused = false
						self.selectedDetent = .medium
						if let coordinate = item.coordinate {
							self.camera = .center(coordinate, zoom: 16)
						}
						self.selectedPOI = item.poi
						self.detailSheetShown = true
					case .appleCompletion:
						self.searchIsFocused = false
						Task {
							let items = try await self.viewModel.resolve(prediction: item)
							if let firstResult = items.first, items.count == 1 {
								self.show(row: firstResult)
							} else {
								self.viewModel.items = items
							}
						}
					case .appleMapItem:
						self.show(row: item)
					}
				}, label: {
					SearchResultItem(prediction: item)
						.frame(maxWidth: .infinity)
				})
				.listRowSeparator(.hidden)
				.listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 2, trailing: 8))
			}
			.onChange(of: searchText) { newValue in
				self.viewModel.searchText = newValue
			}
			.listStyle(.plain)
		}
		.sheet(isPresented: $detailSheetShown) {
			if let poi = self.selectedPOI {
				POIDetailSheet(poi: poi, isShown: $detailSheetShown) {
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
		.padding(.vertical, 8)
	}

	func show(row: Row) {
		self.searchIsFocused = false
		self.selectedDetent = .medium
		if let coordinate = row.coordinate {
			self.camera = .center(coordinate, zoom: 16)
		}
		self.selectedPOI = row.poi
		self.detailSheetShown = true
	}
}

#Preview {
	let sheet = SearchSheet(viewModel: .init(mode: .preview),
								camera: .constant(.center(.vienna, zoom: 12)),
								selectedPOI: .constant(nil),
								selectedDetent: .constant(.medium))
	return sheet
}
