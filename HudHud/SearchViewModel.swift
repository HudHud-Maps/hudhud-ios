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

@MainActor
class SearchViewModel: ObservableObject {
	
	enum Mode {
		case live
		case preview
	}

	private let toursprung: ToursprungPOI = .init()
	private let mode: Mode

	@Published var items: [POI] = []
	@Published var searchText: String = ""

	// MARK: - Lifecycle

	init(mode: Mode = .live) {
		self.mode = mode
		if mode == .preview {
			self.items = [
				.starbucks,
				.ketchup
			]
		}
	}

	// MARK: - SearchViewModel

	func search() async {
		let results = await self.fetchData(query: self.searchText)
		self.items = results
	}
}

// MARK: - Private

private extension SearchViewModel {

	func fetchData(query: String) async -> [POI] {
		return try! await toursprung.search(term: query)
	}
}
