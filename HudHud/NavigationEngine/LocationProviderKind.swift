//
//  LocationProviderKind.swift
//  HudHud
//
//  Created by Ali Hilal on 17/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

enum LocationProviderKind {
    case simulated
    case coreLocation

    // MARK: Static Computed Properties

    static var current: Self {
        if DebugStore().simulateRide {
            return .simulated
        } else {
            return .coreLocation
        }
    }
}
