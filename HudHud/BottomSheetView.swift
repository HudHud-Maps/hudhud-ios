//
//  BottomSheetView.swift
//  HudHud
//
//  Created by Patrick Kladek on 01.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SwiftUI
import POIService
import ToursprungPOI
import MapLibreSwiftUI

struct BottomSheetView: View {
	private let toursprung: ToursprungPOI = .init()

	@StateObject private var viewModel = SearchViewModel()
	@FocusState private var searchIsFocused: Bool
	@State private var isShown: Bool = false
	@State private var searchText = ""

	@Binding var camera: MapViewCamera
	@Binding var selectedPOI: POI?
	@Binding var selectedDetent: PresentationDetent

	var body: some View {
		GroupBox {
			VStack {
				// Search bar
				HStack {
					Image(systemName: "magnifyingglass")
						.foregroundColor(.gray)
						.padding(.leading, 8)
					TextField("Search", text: $searchText)
						.focused($searchIsFocused)
						.padding(.vertical, 10)
						.padding(.horizontal, 0)
						.cornerRadius(8)
						.overlay(
							HStack {
								Spacer()
								if !self.searchText.isEmpty {
									Button(action: {
										self.searchText = ""
									}) {
										Image(systemName: "multiply.circle.fill")
											.foregroundColor(.gray)
											.padding(.vertical)
									}
								}
							}
								.padding(.horizontal, 8)
						)
						.padding(.horizontal, 10)
				}
				.background(.white)
				.cornerRadius(8)

				List(self.viewModel.items) { item in
					Button(item.name) {
						print("tapped")
						self.searchIsFocused = false
						self.selectedDetent = .medium
						self.camera = .center(item.locationCoordinate, zoom: 16)
						self.selectedPOI = item

						self.isShown = true
					}
				}
				.onChange(of: searchText) { newValue in
					Task {
						self.viewModel.searchText = newValue
						await self.viewModel.search()
					}
				}
				.listStyle(.plain)
				.cornerRadius(8.0)
				.padding(.vertical, 10)
			}
		}
		.sheet(isPresented: $isShown) {
			if let poi = self.selectedPOI {
				POISheet(poi: poi, isShown: $isShown) {
					print("start")
				} onMore: {
					print("more")
				}
				.presentationDetents([.third])
				.presentationBackgroundInteraction(
					.enabled(upThrough: .third)
				)
				.interactiveDismissDisabled()
				.ignoresSafeArea()
			}
		}
	}

	func searchResults() async -> [String] {
		if searchText.isEmpty {
			return []
		} else {
			return try! await self.toursprung.search(term: searchText).map { $0.name }
		}
	}
}

#Preview {
	BottomSheetView(camera: .constant(.center(.vienna, zoom: 12)),
					selectedPOI: .constant(.ketchup), 
					selectedDetent: .constant(.medium))
}
//struct ContentView_Previews: PreviewProvider {
//	static var previews: some View {
//
//	}
//}
