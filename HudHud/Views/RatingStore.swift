//
//  RatingStore.swift
//  HudHud
//
//  Created by Fatima Aljaber on 09/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SwiftUI

@Observable
class RatingStore {

    // MARK: Properties

    let staticRating: Double
    let ratingsCount: Int
    var interactiveRating: Int

    // MARK: Lifecycle

    init(staticRating: Double, ratingsCount: Int, interactiveRating: Int = 0) {
        self.staticRating = staticRating
        self.ratingsCount = ratingsCount
        self.interactiveRating = interactiveRating
    }

    // MARK: Functions

    // Convert rating number to corresponding label
    func getText() -> String {
        switch self.interactiveRating {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Very Good"
        case 5: return "Excellent"
        default: return ""
        }
    }
}
