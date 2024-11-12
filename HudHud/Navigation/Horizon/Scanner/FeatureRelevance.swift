//
//  FeatureRelevance.swift
//  HudHud
//
//  Created by Ali Hilal on 06/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation

enum FeatureRelevance {
    case notRelevant
    case relevant(distance: CLLocationDistance)

    // MARK: Computed Properties

    var isRelevant: Bool {
        switch self {
        case .notRelevant: return false
        case .relevant: return true
        }
    }

    var distance: CLLocationDistance? {
        switch self {
        case .notRelevant: return nil
        case let .relevant(distance): return distance
        }
    }
}
