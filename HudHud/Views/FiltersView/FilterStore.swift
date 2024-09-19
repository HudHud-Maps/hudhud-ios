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

    var sortBy: HudHudPOI.SortBy? {
        for filter in self.selectedFilters {
            if case let .sort(sortOption) = filter {
                switch sortOption {
                case .distance:
                    return .distance
                case .relevance:
                    return .relevance
                }
            }
        }
        return nil
    }

    var priceRange: HudHudPOI.PriceRange? {
        for filter in self.selectedFilters {
            if case let .priceRange(priceRangeOption) = filter {
                switch priceRangeOption {
                case .cheap:
                    return .cheap
                case .medium:
                    return .medium
                case .pricy:
                    return .pricy
                case .expensive:
                    return .expensive
                }
            }
        }
        return nil
    }

    var rating: Double? {
        for filter in self.selectedFilters {
            if case let .rating(ratingOption) = filter {
                switch ratingOption {
                case .anyRating:
                    return 0.0
                case .rating3andHalf:
                    return 3.5
                case .rating4:
                    return 4.0
                case .rating4andHalf:
                    return 4.5
                }
            }
        }
        return nil
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
        self.sortSelection = self.selectedFilters.compactMap { if case let .sort(value) = $0 { return value } else { return nil } }.first ?? .relevance
        self.priceSelection = self.selectedFilters.compactMap { if case let .priceRange(value) = $0 { return value } else { return nil } }.first ?? .cheap
        self.ratingSelection = self.selectedFilters.compactMap { if case let .rating(value) = $0 { return value } else { return nil } }.first ?? .anyRating
        self.scheduleSelection = FilterType.ScheduleOption.allCases.first { $0.stringValue == "Any" } ?? .any
        self.openNow = self.selectedFilters.contains(.openNow)
        self.topRated = self.selectedFilters.contains(.topRated)
    }

}

// MARK: - Previewable

extension FilterStore: Previewable {
    static var storeSetUpForPreviewing = FilterStore()
}
