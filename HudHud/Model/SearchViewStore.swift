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

	let mapStore: MapStore

	enum Mode {
		enum Provider: CaseIterable {
			case apple
			case toursprung
		}

		case live(provider: Provider)
		case preview
	}

	private var task: Task<Void, Error>?
	var apple = ApplePOI()
	private var toursprung = ToursprungPOI()
	private var cancellable: AnyCancellable?

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
	}

	// MARK: - Internal

	func updateSheetDetent() {
		print(self.searchText.isEmpty)
		if let routes = mapStore.routes, !routes.routes.isEmpty || mapStore.selectedItem != nil {
			self.selectedDetent = .medium
		} else if !self.searchText.isEmpty {
			self.selectedDetent = .medium
		} else {
			self.selectedDetent = .small
		}
	}
}

// MARK: - Previewable

extension SearchViewStore: Previewable {

	static let storeSetUpForPreviewing = SearchViewStore(mapStore: .storeSetUpForPreviewing, mode: .preview)
}
