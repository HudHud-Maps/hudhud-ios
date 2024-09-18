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

        // MARK: Nested Types

        enum SortOption {
            case relevance
            case distance
        }

        enum PriceRange {
            case cheap
            case medium
            case pricy
            case expensive
        }

        enum RatingOption {
            case anyRating
            case rating3andHalf
            case rating4
            case rating4andHalf
        }
    }

    // MARK: Static Properties

    static let shared = FilterStore()

    // MARK: Properties

    @Published var sortSelection = "Relevance"
    @Published var priceSelection = "one"
    @Published var ratingSelection = "Any"
    @Published var scheduleSelection = "Any"
    @Published var topRated = false
    @Published var openNow = false

    @Published var selectedFilters: [FilterType] = []

    private var cancellables = Set<AnyCancellable>()

    private var isUpdating = false

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

        let sortFilter: FilterType? = {
            switch self.sortSelection {
            case "Distance":
                return .sort(.distance)
            default:
                return .sort(.relevance)
            }
        }()
        if let sortFilter {
            newFilters.append(sortFilter)
        }

        let priceFilter: FilterType? = {
            switch self.priceSelection {
            case "one":
                return .priceRange(.cheap)
            case "two":
                return .priceRange(.medium)
            case "three":
                return .priceRange(.pricy)
            case "four":
                return .priceRange(.expensive)
            default:
                return nil
            }
        }()
        if let priceFilter {
            newFilters.append(priceFilter)
        }

        let ratingFilter: FilterType? = {
            switch self.ratingSelection {
            case "Any":
                return .rating(.anyRating)
            case "3.5":
                return .rating(.rating3andHalf)
            case "4.0":
                return .rating(.rating4)
            case "4.5":
                return .rating(.rating4andHalf)
            default:
                return nil
            }
        }()
        if let ratingFilter {
            newFilters.append(ratingFilter)
        }
        // toggleable Buttons coming from MainFiltersView
        if filter == .openNow {
            self.openNow.toggle()
        }
        if self.scheduleSelection == "Open" || self.openNow {
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

}

// MARK: - Previewable

extension FilterStore: Previewable {
    static var storeSetUpForPreviewing = FilterStore()
}
