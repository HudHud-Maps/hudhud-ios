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
import Combine

@MainActor
class SearchViewModel: ObservableObject {

	enum Mode {
		enum Provider {
			case apple
			case toursprung
		}

		case live(provider: Provider)
		case preview
	}

	@ObservedObject private var apple: ApplePOI = .init()
	@ObservedObject private var searchService: LocationSearchService = .init()
	private let mode: Mode
	private var cancellables: Set<AnyCancellable> = []

	@Published var items: [POI] = []
	var searchText: String = "" {
		didSet {
			switch mode {
			case .live(provider: .apple):
				self.searchService.searchQuery = self.searchText
			case .live(provider: .toursprung):
				Task {
					let results = try await self.fetchData(query: self.searchText)
					self.items = results
				}
			case .preview:
				self.items = [
					.starbucks,
					.ketchup
				]
			}
		}
	}

	// MARK: - Lifecycle

	init(mode: Mode = .live(provider: .toursprung)) {
		self.mode = mode
		switch mode {
		case .live(.apple):
			self.searchText = self.searchService.searchQuery
			self.searchService.$completions
				.receive(on: RunLoop.main)
				.sink { [weak self] completions in
					self?.items = completions
				}
				.store(in: &cancellables)
		default:
			break
		}
	}
}

// MARK: - Private

private extension SearchViewModel {

	func fetchData(query: String) async throws -> [POI] {
		return try await apple.complete(term: query)
	}
}
