//
//  RoutePosition.swift
//  HudHud
//
//  Created by Ali Hilal on 06/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation

struct RoutePosition: Equatable {

    // MARK: Static Properties

    static let invalid = RoutePosition(index: -1, projectedDistance: .infinity)

    // MARK: Properties

    let index: Int
    let projectedDistance: CLLocationDistance

    // MARK: Computed Properties

    var isValid: Bool {
        self != .invalid
    }

    // MARK: Functions

    func isBefore(_ other: RoutePosition) -> Bool {
        self.index < other.index
    }
}
