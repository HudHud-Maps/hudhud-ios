//
//  RatingStore.swift
//  HudHud
//
//  Created by Fatima Aljaber on 09/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - RatingStore

@Observable
final class RatingStore {

    // MARK: Nested Types

    struct State: Equatable {

        // MARK: Properties

        var staticRating: Double
        var ratingsCount: Int
        var interactiveRating: Int

        // MARK: Computed Properties

        var ratingCategory: RatingCategory? {
            RatingCategory(rawValue: self.interactiveRating)
        }
    }

    enum Action {
        case setInteractiveRating(Int)
        case updateStaticRating(rating: Double, count: Int)
        case resetInteractiveRating
    }

    // MARK: Properties

    private(set) var state: State

    // MARK: Lifecycle

    init(staticRating: Double, ratingsCount: Int, interactiveRating: Int = 0) {
        self.state = State(staticRating: staticRating, ratingsCount: ratingsCount, interactiveRating: interactiveRating)
    }

    // MARK: Functions

    func reduce(action: Action) {
        switch action {
        case let .setInteractiveRating(rating):
            guard (1 ... 5).contains(rating) else {
                assertionFailure("Invalid rating value. Must be between 1 and 5.")
                return
            }
            self.state.interactiveRating = rating

        case let .updateStaticRating(rating, count):
            self.state.staticRating = rating
            self.state.ratingsCount = count

        case .resetInteractiveRating:
            self.state.interactiveRating = 0
        }
    }
}

// MARK: - RatingCategory

enum RatingCategory: Int, CaseIterable {
    case poor = 1
    case fair
    case good
    case veryGood
    case excellent

    // MARK: Computed Properties

    var description: String {
        switch self {
        case .poor: return "Poor"
        case .fair: return "Fair"
        case .good: return "Good"
        case .veryGood: return "Very Good"
        case .excellent: return "Excellent"
        }
    }
}
