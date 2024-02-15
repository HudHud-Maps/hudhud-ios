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
			case apple(state: ApplePOI.State)
			case toursprung
		}

		case live(provider: Provider)
		case preview
	}

	@ObservedObject private var apple: ApplePOI = .init()
	@ObservedObject private var toursprung: ToursprungPOI = .init()
	private var mode: Mode
	private var cancellables: Set<AnyCancellable> = []

	@Published var items: [Row] = []
	var searchText: String = "" {
		didSet {
			switch mode {
			case .live(provider: .apple):
				self.apple.searchQuery = self.searchText
			case .live(provider: .toursprung):
				self.toursprung.searchQuery = self.searchText
			case .preview:
				self.items = [
					Row(toursprung: .starbucks),
					Row(toursprung: .ketchup)
				]
			}
		}
	}

	// MARK: - Lifecycle

	init(mode: Mode = .live(provider: .toursprung)) {
		self.mode = mode
		switch mode {
		case .live(.apple):
			self.apple.$results
				.receive(on: RunLoop.main)
				.sink { [weak self] completions in
					self?.items = completions
				}
				.store(in: &cancellables)
		case .live(provider: .toursprung):
			self.toursprung.$results
				.receive(on: RunLoop.main)
				.sink { [weak self] completions in
					self?.items = completions
				}
				.store(in: &cancellables)
		default:
			break
		}
	}

	// MARK: - SearchViewModel

	func update(to state: ApplePOI.State) {
		switch self.mode {
		case .live(let provider):
			switch provider {
			case .apple(let oldState):
				self.apple.state = state
			case .toursprung:
				break
			}
		case .preview:
			break
		}
	}
}
