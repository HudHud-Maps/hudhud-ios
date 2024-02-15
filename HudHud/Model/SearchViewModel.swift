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
	@ObservedObject private var toursprung: ToursprungPOI = .init()
	private let mode: Mode
	private var cancellables: Set<AnyCancellable> = []

	@Published var items: [POI] = []
	var searchText: String = "" {
		didSet {
			switch mode {
			case .live(provider: .apple):
				self.apple.searchQuery = self.searchText
			case .live(provider: .toursprung):
				self.toursprung.searchQuery = self.searchText
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
			self.apple.$completions
				.receive(on: RunLoop.main)
				.sink { [weak self] completions in
					self?.items = completions
				}
				.store(in: &cancellables)
		case .live(provider: .toursprung):
			self.toursprung.$completions
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
