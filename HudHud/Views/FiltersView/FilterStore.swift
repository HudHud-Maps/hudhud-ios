//
//  FilterStore.swift
//  HudHud
//
//  Created by Alaa . on 11/09/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import Combine
import Foundation
import SwiftUI

// MARK: - FilterStore

@MainActor
final class FilterStore: ObservableObject {

    // MARK: Nested Types

    enum FilterType: Equatable {

        case openNow
        case topRated
        case sort(SortOption)
        case priceRange(PriceRange)
        case rating(RatingOption)
        case schedule(ScheduleOption)

        // MARK: Nested Types

        enum SortOption: String, CaseIterable, Hashable {
            case relevance = "Relevance"
            case distance = "Distance"

            // MARK: Computed Properties

            var stringValue: String {
                return self.rawValue
            }
        }

        enum PriceRange: String, CaseIterable, Hashable {
            case cheap = "$"
            case medium = "$$"
            case pricy = "$$$"
            case expensive = "$$$$"

            // MARK: Computed Properties

            var stringValue: String {
                return self.rawValue
            }
        }

        enum RatingOption: String, CaseIterable, Hashable {
            case anyRating = "Any"
            case rating3andHalf = "3.5"
            case rating4 = "4.0"
            case rating4andHalf = "4.5"

            // MARK: Computed Properties

            var stringValue: String {
                return self.rawValue
            }
        }

        enum ScheduleOption: String, CaseIterable, Hashable {
            case any = "Any"
            case open = "Open"
            case custom = "Custom"

            // MARK: Computed Properties

            var stringValue: String {
                return self.rawValue
            }
        }
    }

    // MARK: Static Properties

    static let shared = FilterStore()

    // MARK: Properties

    @Published var sortSelection: FilterType.SortOption = .relevance
    @Published var priceSelection: FilterType.PriceRange = .cheap
    @Published var ratingSelection: FilterType.RatingOption = .anyRating
    @Published var scheduleSelection: FilterType.ScheduleOption = .any
    @Published var topRated = false
    @Published var openNow = false

    @Published var selectedFilters: [FilterType] = []

    private var cancellables = Set<AnyCancellable>()

    private var isUpdating = false

    private var originalFilters: [FilterType] = []

    // MARK: Computed Properties

    // Computed Properties for Enums - to make the view prettier
    var sortOptions: [SegmentOption<FilterType.SortOption>] {
        FilterType.SortOption.allCases.map { SegmentOption(value: $0, label: .text($0.stringValue)) }
    }

    var priceOptions: [SegmentOption<FilterType.PriceRange>] {
        FilterType.PriceRange.allCases.map { SegmentOption(value: $0, label: .text($0.stringValue)) }
    }

    var ratingOptions: [SegmentOption<FilterType.RatingOption>] {
        FilterType.RatingOption.allCases.map { option in
            if option == .anyRating {
                return SegmentOption(value: option, label: .text(option.stringValue))
            } else {
                return SegmentOption(value: option, label: .textWithSymbol(option.stringValue, .starFill))
            }
        }
    }

    var scheduleOptions: [SegmentOption<FilterType.ScheduleOption>] {
        FilterType.ScheduleOption.allCases.map { SegmentOption(value: $0, label: .text($0.stringValue)) }
    }

    // MARK: Functions

    func applyFilters(_ filter: FilterType? = nil) {
        var newFilters: [FilterType] = []

        let sortFilter: FilterType? = .sort(self.sortSelection)
        if let sortFilter {
            newFilters.append(sortFilter)
        }

        let priceFilter: FilterType? = .priceRange(self.priceSelection)
        if let priceFilter {
            newFilters.append(priceFilter)
        }

        let ratingFilter: FilterType? = .rating(self.ratingSelection)
        if let ratingFilter {
            newFilters.append(ratingFilter)
        }
        // toggleable Buttons coming from MainFiltersView
        if filter == .openNow {
            self.openNow.toggle()
        }
        if self.scheduleSelection == .open || self.openNow {
            newFilters.append(.openNow)
        }

        if filter == .topRated {
            self.topRated.toggle()
        }
        if self.topRated {
            newFilters.append(.topRated)
        }

        if self.selectedFilters != newFilters {
            self.selectedFilters = newFilters
        }
    }

    func saveCurrentFilters() {
        self.originalFilters = self.selectedFilters
    }

    func resetFilters() {
        self.selectedFilters = self.originalFilters
        // Reset individual properties if needed
        self.sortSelection = self.selectedFilters.compactMap {
            if case let .sort(value) = $0 {
                return value
            } else {
                return nil
            }
        }.first ?? .relevance
        self.priceSelection = self.selectedFilters.compactMap {
            if case let .priceRange(value) = $0 {
                return value
            } else {
                return nil
            }
        }.first ?? .cheap
        self.ratingSelection = self.selectedFilters.compactMap {
            if case let .rating(value) = $0 {
                return value
            } else {
                return nil
            }
        }.first ?? .anyRating
        self.scheduleSelection = FilterType.ScheduleOption.allCases.first { $0.stringValue == "Any" } ?? .any
        self.openNow = self.selectedFilters.contains(.openNow)
        self.topRated = self.selectedFilters.contains(.topRated)
    }

}

// MARK: - Previewable

extension FilterStore: Previewable {
    static var storeSetUpForPreviewing = FilterStore()
}

extension FilterStore.FilterType.SortOption {
    var hudHudSortBy: HudHudPOI.SortBy? {
        let sortByMapping: [FilterStore.FilterType.SortOption: HudHudPOI.SortBy] = [
            .distance: .distance,
            .relevance: .relevance
        ]
        return sortByMapping[self]
    }
}

extension FilterStore.FilterType.PriceRange {
    var hudHudPriceRange: HudHudPOI.PriceRange? {
        let priceRangeMapping: [FilterStore.FilterType.PriceRange: HudHudPOI.PriceRange] = [
            .cheap: .cheap,
            .medium: .medium,
            .pricy: .pricy,
            .expensive: .expensive
        ]
        return priceRangeMapping[self]
    }
}
