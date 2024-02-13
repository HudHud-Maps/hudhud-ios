//
//  SearchViewModel.swift
//  HudHud
//
//  Created by Patrick Kladek on 02.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import ApplePOI
import Foundation
import POIService
import ToursprungPOI
import SwiftUI
import MapKit

@MainActor
class SearchViewModel: ObservableObject {
	
	enum Mode {
		case live
		case preview
	}

	@ObservedObject private var apple: ApplePOI = .init()
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

	func search() async throws {
		let results = try await self.fetchData(query: self.searchText)
		self.items = results
	}
}

// MARK: - Private

private extension SearchViewModel {

	func fetchData(query: String) async throws -> [POI] {
		return try await apple.complete(term: query).map {
			POI(name: $0.subtitle, subtitle: $0.subtitle, locationCoordinate: .vienna, type: "")
		}
	}
}
