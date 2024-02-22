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

@MainActor
class SearchViewStore: ObservableObject {

	enum Mode {
		enum Provider: CaseIterable {
			case apple
			case toursprung
		}

		case live(provider: Provider)
		case preview
	}

	private var task: Task<(), Error>?
	private var apple: ApplePOI = .init()
	private var toursprung: ToursprungPOI = .init()
	private var cancellable: AnyCancellable?

	// MARK: - Properties

	@Published var items: [Row] = []
	@Published var searchText: String = ""
	@Published var mode: Mode {
		didSet {
			self.searchText = ""
			self.items = []
		}
	}

	// MARK: - Lifecycle

	init(mode: Mode) {
		self.mode = mode

		self.cancellable = $searchText
			.removeDuplicates()
			.sink { newValue in
				switch self.mode {
				case .live(provider: .apple):
					self.task?.cancel()
					self.task = Task {
						self.items = try await self.apple.predict(term: newValue)
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
	}

	// MARK: - SearchViewModel

	func resolve(prediction: Row) async throws -> [Row] {
		switch prediction.provider {
		case .appleCompletion(let completion):
			return try await self.apple.lookup(prediction: .apple(completion: completion))
		case .appleMapItem(let mapItem):
			return [Row(mapItem: mapItem)]
		case .toursprung(let poi):
			return [Row(toursprung: poi)]
		}
	}
}
