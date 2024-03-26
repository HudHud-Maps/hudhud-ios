//
//  SearchViewStore.swift
//  HudHud
//
//  Created by Patrick Kladek on 02.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import ApplePOI
import Combine
import Foundation
import POIService
import SwiftUI
import ToursprungPOI

// MARK: - SearchViewStore

@MainActor
class SearchViewStore: ObservableObject {

	var mapStore: MapStore = .init()

	enum Mode {
		enum Provider: CaseIterable {
			case apple
			case toursprung
		}

		case live(provider: Provider)
		case preview
	}

	private var task: Task<Void, Error>?
	private var apple: ApplePOI = .init()
	private var toursprung: ToursprungPOI = .init()
	private var cancellable: AnyCancellable?

	// MARK: - Properties

	@Published var searchText: String = ""
	@Published var mode: Mode {
		didSet {
			self.searchText = ""
			self.mapStore.mapItemStatus = .empty
		}
	}

	@Published var selectedDetent: PresentationDetent = .small
	@Published var isSearching = false

	// MARK: - Lifecycle

	init(mode: Mode) {
		self.mode = mode

		self.cancellable = self.$searchText
			.removeDuplicates()
			.sink { newValue in
				switch self.mode {
				case .live(provider: .apple):
					self.task?.cancel()
					self.task = Task {
						self.isSearching = true
						let newStatus = try await MapItemsStatus(selectedItem: nil, mapItems: self.apple.predict(term: newValue))
						self.mapStore.mapItemStatus = newStatus
						self.isSearching = false
					}
				case .live(provider: .toursprung):
					self.task?.cancel()
					self.task = Task {
						self.isSearching = true
						let newStatus = try await MapItemsStatus(selectedItem: nil, mapItems: self.toursprung.predict(term: newValue))
						self.mapStore.mapItemStatus = newStatus
						self.isSearching = false
					}
				case .preview:
					let newStatus = MapItemsStatus(selectedItem: nil, mapItems: [
						.init(toursprung: .starbucks),
						.init(toursprung: .ketchup),
						.init(toursprung: .publicPlace),
						.init(toursprung: .artwork),
						.init(toursprung: .pharmacy),
						.init(toursprung: .supermarket)
					])
					self.mapStore.mapItemStatus = newStatus
				}
			}
	}

	// MARK: - Internal

	// MARK: - SearchViewStore

	func resolve(prediction: Row) async throws -> [Row] {
		switch prediction.provider {
		case let .appleCompletion(completion):
			return try await self.apple.lookup(prediction: .apple(completion: completion))
		case let .appleMapItem(mapItem):
			return [Row(mapItem: mapItem)]
		case let .toursprung(poi):
			return [Row(toursprung: poi)]
		}
	}
}

extension SearchViewStore {
	static var preview: SearchViewStore {
		.init(mode: .preview)
	}
}
