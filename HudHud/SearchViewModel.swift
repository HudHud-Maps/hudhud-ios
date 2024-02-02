//
//  SearchViewModel.swift
//  HudHud
//
//  Created by Patrick Kladek on 02.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import ToursprungPOI
import POIService

@MainActor // Ensures UI updates on the main thread.
class SearchViewModel: ObservableObject {
	
	private let toursprung: ToursprungPOI = .init()

	@Published var items: [POI] = []
	@Published var searchText: String = ""

	func search() async {
		// Simulate an API call
		let results = await fetchData(query: searchText)
		self.items = results
	}

	private func fetchData(query: String) async -> [POI] {
		return try! await toursprung.search(term: query)
	}
}
