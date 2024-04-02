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
final class SearchViewStore: ObservableObject {

	@NestedObservableObject var mapStore: MapStore

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
			self.mapStore.mapItemStatus.mapItems = []
			self.mapStore.mapItemStatus.selectedItem = nil
		}
	}

	@Published var selectedDetent: PresentationDetent = .small

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
						self.mapStore.mapItemStatus.mapItems = try await self.apple.predict(term: newValue)
					}
				case .live(provider: .toursprung):
					self.task?.cancel()
					self.task = Task {
						self.mapStore.mapItemStatus.mapItems = try await self.toursprung.predict(term: newValue)
					}
				case .preview:
					self.mapStore.mapItemStatus.mapItems = [
						.init(toursprung: .starbucks),
						.init(toursprung: .ketchup),
						.init(toursprung: .publicPlace),
						.init(toursprung: .artwork),
						.init(toursprung: .pharmacy),
						.init(toursprung: .supermarket)
					]
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
		let mapItemStatus = MapItemsStatus(mapItems: [], motionViewModel: .init())
		return SearchViewStore(mapStore: .init(mapItemStatus: mapItemStatus), mode: .preview)
	}
}
