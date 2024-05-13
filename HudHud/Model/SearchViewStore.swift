//
//  SearchViewStore.swift
//  HudHud
//
//  Created by Patrick Kladek on 02.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Combine
import Foundation
import POIService
import SwiftUI

// MARK: - SearchViewStore

@MainActor
final class SearchViewStore: ObservableObject {

	enum SearchType: Equatable {

		case selectPOI
		case returnPOILocation(completion: ((ABCRouteConfigurationItem) -> Void)?)

		// MARK: - Internal

		static func == (lhs: SearchType, rhs: SearchType) -> Bool {
			switch (lhs, rhs) {
			case (.selectPOI, .selectPOI):
				return true
			case let (.returnPOILocation(lhsCompletion), .returnPOILocation(rhsCompletion)):
				// Compare the optional closures using their identity
				return lhsCompletion as AnyObject === rhsCompletion as AnyObject
			default:
				return false
			}
		}
	}

	enum Mode {
		enum Provider: CaseIterable {
			case apple
			case toursprung
		}

		case live(provider: Provider)
		case preview
	}

	let mapStore: MapStore

	private var task: Task<Void, Error>?
	var apple = ApplePOI()
	private var toursprung = ToursprungPOI()
	private var cancellable: AnyCancellable?
	private var cancellables: Set<AnyCancellable> = []

	// MARK: - Properties

	@Published var searchText: String = ""
	@Published var mode: Mode {
		didSet {
			self.searchText = ""
			self.mapStore.displayableItems = []
			self.mapStore.selectedItem = nil
		}
	}

	@Published var selectedDetent: PresentationDetent = .small
	@Published var isSearching = false
	@Published var searchType: SearchType = .selectPOI

	@AppStorage("RecentViewedItem") var recentViewedItem = [ResolvedItem]()

	// MARK: - Lifecycle

	init(mapStore: MapStore, mode: Mode) {
		self.mapStore = mapStore
		self.mode = mode

		self.cancellable = self.$searchText
			.removeDuplicates()
			.sink { newValue in
				switch self.mode {
				case .live(provider: .apple):
					self.task?.cancel()
					self.task = Task {
						defer { self.isSearching = false }
						self.isSearching = true

						let prediction = try await self.apple.predict(term: newValue)
						let items = prediction
						self.mapStore.displayableItems = items
					}
				case .live(provider: .toursprung):
					self.task?.cancel()
					self.task = Task {
						defer { self.isSearching = false }
						self.isSearching = true

						let prediction = try await self.toursprung.predict(term: newValue)
						let items = prediction
						self.mapStore.displayableItems = items
					}
				case .preview:
					self.mapStore.displayableItems = [
						.starbucks,
						.ketchup,
						.publicPlace,
						.artwork,
						.pharmacy,
						.supermarket
					]
				}
			}
		if case .preview = mode {
			let itemOne = ResolvedItem(id: "1", title: "Starbucks", subtitle: "Main Street 1", type: .toursprung, coordinate: .riyadh)
			let itemTwo = ResolvedItem(id: "2", title: "Motel One", subtitle: "Main Street 2", type: .toursprung, coordinate: .riyadh)
			self.recentViewedItem = [itemOne, itemTwo]
		}
		self.$searchText
			.debounce(for: .milliseconds(300), scheduler: RunLoop.main)
			.removeDuplicates()
			.sink { [weak self] _ in
				self?.updateSheetDetent()
			}
			.store(in: &self.cancellables)

		self.mapStore.$selectedItem
			.sink { [weak self] _ in
				self?.updateSheetDetent()
			}
			.store(in: &self.cancellables)
	}

	// MARK: - Internal

	// Updates the presentation detent based on the current state of the search

	func updateSheetDetent() {
		// If routes exist or an item is selected, use the medium detent
		if let routes = mapStore.routes, !routes.routes.isEmpty || mapStore.selectedItem != nil {
			self.selectedDetent = .medium
		} else if !self.searchText.isEmpty {
			// If search text is not empty, also use the medium detent
			self.selectedDetent = .medium
		} else {
			// Otherwise, use the small detent
			self.selectedDetent = .small
		}
	}
}

// MARK: - Previewable

extension SearchViewStore: Previewable {

	static let storeSetUpForPreviewing = SearchViewStore(mapStore: .storeSetUpForPreviewing, mode: .preview)
}
