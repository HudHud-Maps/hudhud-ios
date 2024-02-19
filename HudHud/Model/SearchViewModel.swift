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

@MainActor
class SearchViewModel: ObservableObject {

	enum Mode {
		enum Provider: CaseIterable {
			case apple
			case toursprung
		}

		case live(provider: Provider)
		case preview
	}

	private var apple: ApplePOI = .init()
	private var toursprung: ToursprungPOI = .init()
	var mode: Binding<Mode>

	@Published var items: [Row] = []
	var searchText: String = "" {
		didSet {
			switch self.mode.wrappedValue {
			case .live(provider: .apple):
				Task {
					self.items = try await self.apple.predict(term: self.searchText)
				}
			case .live(provider: .toursprung):
				Task {
					self.items = try await self.toursprung.predict(term: self.searchText)
				}
			case .preview:
				self.items = [
					.init(toursprung: .starbucks),
					.init(toursprung: .ketchup)
				]
			}
		}
	}

	// MARK: - Lifecycle

	init(mode: Binding<Mode>) {
		self.mode = mode
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
