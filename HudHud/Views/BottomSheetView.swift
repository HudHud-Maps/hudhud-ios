//
//  BottomSheetView.swift
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

struct BottomSheetView: View {
	enum DataProvider {
		case toursprung
		case apple
	}

	@ObservedObject var viewModel: SearchViewModel
	@FocusState private var searchIsFocused: Bool
	@State private var isShown: Bool = false
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
					self.searchIsFocused = false
					self.selectedDetent = .medium
					self.camera = .center(item.locationCoordinate, zoom: 16)
					self.selectedPOI = item
					self.isShown = true
				}, label: {
					SearchResultItem(poi: item)
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
		.sheet(isPresented: $isShown) {
			if let poi = self.selectedPOI {
				POISheet(poi: poi, isShown: $isShown) {
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
}

#Preview {
	let sheet = BottomSheetView(viewModel: .init(mode: .preview),
								camera: .constant(.center(.vienna, zoom: 12)),
								selectedPOI: .constant(nil),
								selectedDetent: .constant(.medium))
	return sheet
}
