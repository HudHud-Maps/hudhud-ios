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
import SwiftUI

// MARK: - SearchViewStore

@MainActor
final class SearchViewStore: ObservableObject {

    // MARK: Nested Types

    enum SearchType: Equatable {

        case selectPOI
        case returnPOILocation(completion: ((ABCRouteConfigurationItem) -> Void)?)
        case categories
        case favorites

        // MARK: Static Functions

        static func == (lhs: SearchType, rhs: SearchType) -> Bool {
            switch (lhs, rhs) {
            case (.selectPOI, .selectPOI):
                true
            case let (.returnPOILocation(lhsCompletion), .returnPOILocation(rhsCompletion)):
                // Compare the optional closures using their identity
                lhsCompletion as AnyObject === rhsCompletion as AnyObject
            case (.favorites, .favorites):
                true
            case (.categories, categories):
                true
            default:
                false
            }
        }
    }

    enum Mode {
        case live(provider: Provider)
        case preview

        // MARK: Nested Types

        enum Provider: CaseIterable {
            case apple
            case hudhud
        }

    }

    // MARK: Properties

    let mapStore: MapStore
    let routingStore: RoutingStore
    var apple = ApplePOI()

    @Published var searchText: String = ""
    @Published var searchError: Error?
    @Published var isSheetLoading = false
    @Published var searchType: SearchType = .selectPOI

    @AppStorage("RecentViewedItem") var recentViewedItem = [ResolvedItem]()

    @ObservedObject var filterStore: FilterStore

    private let mapViewStore: MapViewStore

    private var task: Task<Void, Error>?
    private var hudhud = HudHudPOI()
    private var cancellables: Set<AnyCancellable> = []

    // MARK: Computed Properties

    @Published var mode: Mode {
        didSet {
            self.searchText = ""
            self.mapStore.displayableItems = []
            self.mapStore.selectedItem = nil
        }
    }

    // MARK: Lifecycle

    init(mapStore: MapStore, mapViewStore: MapViewStore, routingStore: RoutingStore, filterStore: FilterStore, mode: Mode) {
        self.mapStore = mapStore
        self.routingStore = routingStore
        self.mapViewStore = mapViewStore
        self.filterStore = filterStore
        self.mode = mode

        self.bindSearchAutoComplete()
        if case .preview = mode {
            let itemOne = ResolvedItem(id: "1", title: "Starbucks", subtitle: "Main Street 1", type: .appleResolved, coordinate: .riyadh, color: .systemRed)
            let itemTwo = ResolvedItem(id: "2", title: "Motel One", subtitle: "Main Street 2", type: .appleResolved, coordinate: .riyadh, color: .systemRed)
            self.recentViewedItem = [itemOne, itemTwo]
        }

        filterStore.$selectedFilters
            .sink { [weak self] filters in
                guard let self else { return }
                Task {
                    await self.fetch(category: self.searchText, filters: filters)
                }
            }
            .store(in: &self.cancellables)
    }

    // MARK: Functions

    func didSelect(_ item: DisplayableRow) async {
        switch item {
        case let .resolvedItem(item):
            await self.mapStore.resolve(item)
        case let .categoryItem(resolvedItem):
            self.mapViewStore.selectedDetent = .third
            self.mapStore.selectedItem = resolvedItem
        case let .category(category):
            await self.fetch(category: category.name)
        case .predictionItem:
            await self.resolve(item: item)
        }
    }

    func resolve(item: DisplayableRow) async {
        self.mapViewStore.selectedDetent = .third
        self.isSheetLoading = true
        defer { self.isSheetLoading = false }
        do {
            let items = switch self.mode {
            case .live(provider: .apple):
                try await item.resolve(in: self.apple, baseURL: "") // no need to sent url
            case .live(provider: .hudhud):
                try await item.resolve(in: self.hudhud, baseURL: DebugStore().baseURL)
            case .preview:
                [item]
            }
            guard let firstItem = items.first,
                  let resolvedItem = firstItem.resolvedItem,
                  items.count == 1,
                  let resolvedItemIndex = self.mapStore.displayableItems.firstIndex(where: { $0.id == resolvedItem.id }) else {
                self.mapViewStore.selectedDetent = .large
                self.mapStore.displayableItems = items
                return
            }
            self.mapStore.displayableItems[resolvedItemIndex] = .resolvedItem(resolvedItem)
            self.mapStore.selectedItem = resolvedItem
            self.mapViewStore.selectedDetent = .third
        } catch {
            self.searchError = error
        }
    }

    func fetch(category: String, filters _: [FilterStore.FilterType] = []) async {
        guard !category.isEmpty else { return }

        self.searchType = .categories
        defer { self.searchType = .selectPOI }

        self.searchText = category

        self.isSheetLoading = true
        defer { isSheetLoading = false }
        do {
            let userLocation = await self.mapStore.userLocationStore.location()?.coordinate
            let items = try await hudhud.items(for: category, topRated: self.filterStore.topRated, priceRange: self.filterStore.priceRange, sortBy: self.filterStore.sortBy, rating: self.filterStore.rating, location: userLocation, baseURL: DebugStore().baseURL)
            self.mapStore.displayableItems = items.map(DisplayableRow.categoryItem)
        } catch {
            self.searchError = error
            Logger.poiData.error("fetching category error: \(error)")
        }
    }

    // will called if the user pressed search in keyboard
    func fetchEnterResults() async {
        self.searchType = .categories
        defer { self.searchType = .selectPOI }

        self.mapViewStore.selectedDetent = .third

        self.isSheetLoading = true
        defer { isSheetLoading = false }
        do {
            let userLocation = await self.mapStore.userLocationStore.location()?.coordinate
            let results = try await self.hudhud.predict(term: self.searchText, coordinates: userLocation, baseURL: DebugStore().baseURL)
            self.mapStore.displayableItems = results.items.compactMap { item in
                if let resolvedItem = item.resolvedItem {
                    return DisplayableRow.categoryItem(resolvedItem)
                }
                return nil
            }
        } catch {
            self.searchError = error
            Logger.poiData.error("fetching category error: \(error)")
        }
    }

    func endTrip() {
        self.routingStore.endTrip()
        self.mapStore.selectedItem = nil
        self.mapStore.displayableItems = []
        self.searchText = ""
        self.mapViewStore.reset()
    }

    func storeInRecent(_ item: ResolvedItem) {
        if self.recentViewedItem.count > 9 {
            self.recentViewedItem.removeLast()
        }
        if self.recentViewedItem.contains(item) {
            self.recentViewedItem.removeAll(where: { $0 == item })
        }
        self.recentViewedItem.insert(item, at: 0)
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
            self.mapViewStore.selectedDetent = .third

            let userLocation = await self.mapStore.userLocationStore.location()?.coordinate
            do {
                let result = switch provider {
                case .apple:
                    try await self.apple.predict(term: term, coordinates: userLocation, baseURL: "") // no need to send URL
                case .hudhud:
                    try await self.hudhud.predict(term: term, coordinates: userLocation, baseURL: DebugStore().baseURL)
                }
                self.searchError = nil
                self.mapStore.displayableItems = result.items
                self.mapViewStore.selectedDetent = if provider == .hudhud, result.hasCategory {
                    .small // hudhud provider has coordinates in the response, so we can show the results in the map
                } else {
                    .large // other providers do not return coordinates, so we show the result in a list in full page
                }
            } catch is CancellationError {
                Logger.poiData.debug("Task cancelled")
            } catch {
                if Task.isCancelled {
                    Logger.poiData.error("Task cancelled")
                } else {
                    self.searchError = error
                    Logger.poiData.error("Predict Error: \(error)")
                }
            }
        }
    }

    func bindSearchAutoComplete() {
        self.$searchText
            .removeDuplicates()
            .sink { [weak self] searchTerm in
                guard let self, self.searchType != .categories else { return }
                switch self.mode {
                case let .live(provider):
                    self.performSearch(with: provider, term: searchTerm)
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
    }

//    func bindFilterSearch() {
//
//    }
}

// MARK: - Previewable

extension SearchViewStore: Previewable {

    static let storeSetUpForPreviewing = SearchViewStore(mapStore: .storeSetUpForPreviewing, mapViewStore: .storeSetUpForPreviewing, routingStore: .storeSetUpForPreviewing, filterStore: .shared, mode: .preview)
}
