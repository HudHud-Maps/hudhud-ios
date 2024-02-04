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
	let names = ["Holly", "Josh", "Rhonda", "Ted"]
	private let toursprung: ToursprungPOI = .init()
	@State private var searchText = ""
	@Binding var camera: MapViewCamera
	@Binding var selectedDetent: PresentationDetent
	@StateObject private var viewModel = SearchViewModel()
	@FocusState private var searchIsFocused: Bool

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
								if !searchText.isEmpty {
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

				List(viewModel.items) { item in
					Text(item.name)
						.onTapGesture {
							print("tapped")
							self.searchIsFocused = false
							self.selectedDetent = .medium
							self.camera = .center(item.locationCoordinate, zoom: 16)
						}
				}
				.onChange(of: searchText) { newValue in
					Task {
						viewModel.searchText = newValue
						await viewModel.search()
					}
				}
				.listStyle(.plain)
				.cornerRadius(8.0)
				.padding(.vertical, 10)
			}
		}
	}

	func searchResults() async -> [String] {
		if searchText.isEmpty {
			return names
		} else {
			return try! await self.toursprung.search(term: searchText).map { $0.name }
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		BottomSheetView(camera: .constant(.center(.vienna, zoom: 12)), selectedDetent: .constant(.medium))
	}
}
