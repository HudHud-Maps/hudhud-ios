//
//  SearchViewStore.swift
//  HudHud
//
//  Created by Patrick Kladek on 02.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import Combine
import CoreLocation
import Foundation
import OSLog
import SwiftLocation
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
            case hudhud
        }

        case live(provider: Provider)
        case preview
    }

    let mapStore: MapStore

    private var task: Task<Void, Error>?
    var apple = ApplePOI()
    private var toursprung = ToursprungPOI()
    private var hudhud = HudHudPOI()
    private var cancellable: AnyCancellable?
    private var cancellables: Set<AnyCancellable> = []
    var locationManager: Location = .forSingleRequestUsage

    // MARK: - Properties

    @Published var searchText: String = ""
    @Published var searchError: Error?
    @Published var mode: Mode {
        didSet {
            self.searchText = ""
            self.mapStore.displayableItems = []
            self.mapStore.selectedItem = nil
        }
    }

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
                case let .live(provider):
                    self.performSearch(with: provider, term: newValue)
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

    func getCurrentLocation() async -> CLLocationCoordinate2D? {
        guard let currentLocation = try? await self.locationManager.requestLocation().location?.coordinate else {
            return nil
        }
        return currentLocation
    }

    // MARK: - Private

    private func performSearch(with provider: Mode.Provider, term: String) {
        self.task?.cancel()
        self.task = Task {
            defer { self.isSearching = false }
            self.isSearching = true

            do {
                let prediction: [AnyDisplayableAsRow] = switch provider {
                case .apple:
                    try await self.apple.predict(term: term, coordinates: self.getCurrentLocation())
                case .toursprung:
                    try await self.toursprung.predict(term: term, coordinates: self.getCurrentLocation())
                case .hudhud:
                    try await self.hudhud.predict(term: term, coordinates: self.getCurrentLocation())
                }
                self.searchError = nil
                self.mapStore.displayableItems = prediction
            } catch {
                self.searchError = error
                Logger.poiData.error("Predict Error: \(error)")
            }
        }
    }
}

// MARK: - Previewable

extension SearchViewStore: Previewable {

    static let storeSetUpForPreviewing = SearchViewStore(mapStore: .storeSetUpForPreviewing, mode: .preview)
}
