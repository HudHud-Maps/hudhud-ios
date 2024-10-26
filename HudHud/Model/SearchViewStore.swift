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

    @ObservedObjectChild var mapStore: MapStore
    @ObservedObjectChild var navigationVisualization: NavigationVisualization
    var apple = ApplePOI()
    var progressViewTimer: Timer?
    var loadingInstance = Loading()

    @Published var searchText: String = ""
    @Published var searchError: Error?
    @Published var isSheetLoading = false
    @Published var searchType: SearchType = .selectPOI
    let filterStore: FilterStore

    @AppStorage("RecentViewedItem") var recentViewedItem = [ResolvedItem]()

    private let sheetStore: SheetStore
    private var task: Task<Void, Error>?
    private var hudhud = HudHudPOI()
    private var cancellables: Set<AnyCancellable> = []

    // MARK: Computed Properties

    @Published var mode: Mode {
        didSet {
            self.searchText = ""
            self.mapStore.clearItems()
        }
    }

    // MARK: Lifecycle

    init(
        mapStore: MapStore,
        sheetStore: SheetStore,
        navigationVisualization: NavigationVisualization,
        filterStore: FilterStore,
        mode: Mode
    ) {
        self.mapStore = mapStore
        self.navigationVisualization = navigationVisualization
        self.sheetStore = sheetStore
        self.filterStore = filterStore
        self.mode = mode

        self.bindSearchAutoComplete()
        if case .preview = mode {
            let itemOne = ResolvedItem(id: "1", title: "Starbucks", subtitle: "Main Street 1", type: .appleResolved, coordinate: .riyadh, color: .systemRed)
            let itemTwo = ResolvedItem(id: "2", title: "Motel One", subtitle: "Main Street 2", type: .appleResolved, coordinate: .riyadh, color: .systemRed)
            self.recentViewedItem = [itemOne, itemTwo]
        }
        self.bindFilterSearch()
    }

    // MARK: Functions

    func didSelect(_ item: DisplayableRow) async {
        switch item {
        case let .resolvedItem(item):
            await self.mapStore.resolve(item)
        case let .categoryItem(resolvedItem):
            self.sheetStore.selectedDetent = .third
            self.mapStore.select(resolvedItem)
        case let .category(category):
            await self.fetch(category: category.name)
        case .predictionItem:
            await self.resolve(item: item)
        }
    }

    func resolve(item: DisplayableRow) async {
        self.sheetStore.selectedDetent = .third
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
                self.sheetStore.selectedDetent = .large
                self.mapStore.displayableItems = items
                return
            }
            self.mapStore.displayableItems[resolvedItemIndex] = .resolvedItem(resolvedItem)
            self.mapStore.select(resolvedItem, shouldFocusCamera: true)
            self.sheetStore.selectedDetent = .third
        } catch {
            self.searchError = error
        }
    }

    func fetch(category: String, enterSearch: Bool = false) async {
        self.loadingInstance.state = .initialLoading
        self.startFetchingResultsTimer()
        self.searchType = .categories
        defer { self.searchType = .selectPOI }

        self.searchText = category

        self.isSheetLoading = true
        defer { isSheetLoading = false }
        do {
            let currentUserLocation = await mapStore.userLocationStore.location(allowCached: true)
            let items = try await hudhud.items(
                for: category,
                enterSearch: enterSearch,
                topRated: self.filterStore.topRated,
                priceRange: self.filterStore.priceSelection.hudHudPriceRange,
                sortBy: self.filterStore.sortSelection.hudHudSortBy,
                rating: Double(self.filterStore.ratingSelection.rawValue),
                location: currentUserLocation?.coordinate,
                baseURL: DebugStore().baseURL
            )

            var filteredItems = items
            // Apply 'open now' filter locally
            if self.filterStore.selectedFilters.contains(.openNow) {
                filteredItems = filteredItems.filter { $0.isOpen == true }
            }

            let displayableItems = filteredItems.map(DisplayableRow.categoryItem)
            self.mapStore.replaceItemsAndFocusCamera(on: displayableItems)
            self.loadingInstance.resultIsEmpty = filteredItems.isEmpty
            self.loadingInstance.state = .result
        } catch {
            self.searchError = error
            Logger.poiData.error("fetching category error: \(error)")
        }
    }

    // will called if the user pressed search in keyboard
    func fetchEnterResults() async {
        self.loadingInstance.state = .initialLoading
        self.startFetchingResultsTimer()

        self.searchType = .categories
        defer { self.searchType = .selectPOI }

        self.sheetStore.selectedDetent = .third

        self.isSheetLoading = true
        defer { isSheetLoading = false }
        do {
            let userLocation = await self.mapStore.userLocationStore.location(allowCached: true)
            let results = try await self.hudhud.predict(term: self.searchText, coordinates: userLocation?.coordinate, baseURL: DebugStore().baseURL)
            let items = results.items.compactMap { item in
                if let resolvedItem = item.resolvedItem {
                    return DisplayableRow.categoryItem(resolvedItem)
                }
                return nil
            }
            self.mapStore.replaceItemsAndFocusCamera(on: items)
            self.loadingInstance.resultIsEmpty = results.items.isEmpty
            self.loadingInstance.state = .result
        } catch {
            self.searchError = error
            Logger.poiData.error("fetching category error: \(error)")
        }
    }

    func endTrip() {
        self.navigationVisualization.stopNavigation()
        self.mapStore.clearItems()
        self.searchText = ""
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

    func startFetchingResultsTimer() {
        // Invalidate any previous timers
        self.progressViewTimer?.invalidate()

        // Start the timer to show the Progress View after 0.2 seconds
        self.progressViewTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
            guard let self else { return }

            Task { @MainActor in
                if self.loadingInstance.state == .initialLoading, self.isSheetLoading {
                    self.loadingInstance.state = .loading
                }
            }
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
            self.isSheetLoading = true
            defer { self.isSheetLoading = false }
            self.sheetStore.selectedDetent = .third

            let userLocation = await self.mapStore.userLocationStore.location(allowCached: true)
            do {
                let result = switch provider {
                case .apple:
                    try await self.apple.predict(term: term, coordinates: userLocation?.coordinate, baseURL: "") // no need to send URL
                case .hudhud:
                    try await self.hudhud.predict(term: term, coordinates: userLocation?.coordinate, baseURL: DebugStore().baseURL)
                }
                self.loadingInstance.resultIsEmpty = result.items.isEmpty
                self.loadingInstance.state = .result
                self.searchError = nil
                self.mapStore.replaceItemsAndFocusCamera(on: result.items)
                self.sheetStore.selectedDetent = if provider == .hudhud, result.hasCategory {
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

    func bindFilterSearch() {
        self.filterStore.$selectedFilters
            .sink { [weak self] _ in
                guard let self else { return }
                guard !self.searchText.isEmpty else { return }
                Task {
                    await self.fetch(category: self.searchText)
                }
            }
            .store(in: &self.cancellables)
    }
}

// MARK: - Previewable

extension SearchViewStore: Previewable {

    static let storeSetUpForPreviewing = SearchViewStore(
        mapStore: .storeSetUpForPreviewing,
        sheetStore: .storeSetUpForPreviewing,
        navigationVisualization: .preview,
        filterStore: .storeSetUpForPreviewing,
        mode: .preview
    )
}

extension NavigationVisualization {
    static var preview: NavigationVisualization {
        .init(
            navigationEngine: NavigationEngine(),
            routePlanner: RoutePlanner(
                routingService: GraphHopperRouteProvider()
            )
        )
    }
}
