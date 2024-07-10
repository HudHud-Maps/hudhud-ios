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
        case favorites

        // MARK: - Internal

        static func == (lhs: SearchType, rhs: SearchType) -> Bool {
            switch (lhs, rhs) {
            case (.selectPOI, .selectPOI):
                return true
            case let (.returnPOILocation(lhsCompletion), .returnPOILocation(rhsCompletion)):
                // Compare the optional closures using their identity
                return lhsCompletion as AnyObject === rhsCompletion as AnyObject
            case (.favorites, .favorites):
                return true
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

    @Published var isSheetLoading = false
    @Published var searchType: SearchType = .selectPOI

    @AppStorage("RecentViewedItem") var recentViewedItem = [ResolvedItem]()

    // MARK: - Lifecycle

    init(mapStore: MapStore, mode: Mode) {
        self.mapStore = mapStore
        self.mode = mode

        self.$searchText
            .removeDuplicates()
            .sink { newValue in
                switch self.mode {
                case let .live(provider):
                    self.performSearch(with: provider, term: newValue)
                case .preview:
                    self.mapStore.displayableItems = [
                        DisplayableRow.starbucks,
                        .ketchup,
                        .publicPlace,
                        .artwork,
                        .pharmacy,
                        .supermarket
                    ]
                }
            }
            .store(in: &self.cancellables)
        if case .preview = mode {
            let itemOne = ResolvedItem(id: "1", title: "Starbucks", subtitle: "Main Street 1", type: .toursprung, coordinate: .riyadh, color: Color(.systemRed))
            let itemTwo = ResolvedItem(id: "2", title: "Motel One", subtitle: "Main Street 2", type: .toursprung, coordinate: .riyadh, color: Color(.systemRed))
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

    func resolve(item: DisplayableRow) async throws -> [DisplayableRow] {
        switch self.mode {
        case .live(provider: .apple):
            return try await item.resolve(in: self.apple)
        case .live(provider: .toursprung):
            return [item] // Toursprung doesn't support predict & resolve
        case .live(provider: .hudhud):
            return try await item.resolve(in: self.hudhud)
        case .preview:
            return [item]
        }
    }

    func fetch(category: String) async {
        self.isSheetLoading = true
        defer { isSheetLoading = false }
        do {
            let items = try await hudhud.items(for: category, location: self.getCurrentLocation())
            self.mapStore.selectedDetent = .small
            self.mapStore.displayableItems = items.map(DisplayableRow.resolvedItem)
        } catch {
            self.searchError = error
            Logger.poiData.error("fetching category error: \(error)")
        }
    }
}

// MARK: - Private

private extension SearchViewStore {

    func performSearch(with provider: Mode.Provider, term: String) {
        self.task?.cancel()
        if term.isEmpty {
            self.mapStore.displayableItems = []
            return
        }
        self.task = Task {
            defer { self.isSheetLoading = false }
            self.isSheetLoading = true
            self.mapStore.selectedDetent = .third

            do {
                let result = switch provider {
                case .apple:
                    try await self.apple.predict(term: term, coordinates: self.getCurrentLocation())
                case .toursprung:
                    try await self.toursprung.predict(term: term, coordinates: self.getCurrentLocation())
                case .hudhud:
                    try await self.hudhud.predict(term: term, coordinates: self.getCurrentLocation())
                }
                self.searchError = nil
                self.mapStore.displayableItems = result.items
                self.mapStore.selectedDetent = if provider == .hudhud, result.hasCategory {
                    .small // hudhud provider has coordinates in the response, so we can show the results in the map
                } else {
                    .large // other providers do not return coordinates, so we show the result in a list in full page
                }
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
