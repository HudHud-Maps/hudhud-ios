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
	private var apple: ApplePOI = .init()
	private var toursprung: ToursprungPOI = .init()
	private var cancellable: AnyCancellable?

	// MARK: - Properties

	@Published var searchText: String = ""


	// you can't have items in two places, one source of truth only
	// @Published var items: [Row]

	@Published var mode: Mode {
		didSet {
			self.searchText = ""
			self.mapStore.mapItemStatus = .empty
		}
	}

	// I think this probably belongs here as we might want to show a map at sometime without a search sheet
	@Published var selectedDetent: PresentationDetent = .small

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
						let newStatus = MapItemsStatus(selectedItem: nil, mapItems: try await self.apple.predict(term: newValue))
						self.mapStore.mapItemStatus = newStatus
					}
				case .live(provider: .toursprung):
					self.task?.cancel()
					self.task = Task {
						self.items = try await self.toursprung.predict(term: newValue)
					}
				case .preview:
					self.items = [
						.init(toursprung: .starbucks),
						.init(toursprung: .ketchup)
					]
				}
			}

		// you might need to set up sinks to self.mapStore.mapItemStatus to clear searchtext...
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
