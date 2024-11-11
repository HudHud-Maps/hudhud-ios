//
//  SpeedLimitViewModifier.swift
//  HudHud
//
//  Created by Ali Hilal on 03.11.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - SpeedLimitViewHost

/// An extension for a NavigationView that can host a SpeedLimitView.
public protocol SpeedLimitViewHost where Self: View {
    var speedLimit: Measurement<UnitSpeed>? { get set }
//    var speedLimitStyle: SpeedLimitView.SignageStyle? { get set }
}

public extension SpeedLimitViewHost {
    /// Configure the NavigationView to display a speed limit
    /// with a specific speed limit signage style.
    ///
    /// - Parameters:
    ///   - speedLimit: The current speed limit in the desired units to display.
    ///   - speedLimitStyle: The style of the signage (US-MUTCD or Vienna Convention).
    /// - Returns: The modified NavigationView.
    func navigationSpeedLimit(speedLimit: Measurement<UnitSpeed>?) -> Self {
        var newSelf = self
        newSelf.speedLimit = speedLimit
//        newSelf.speedLimitStyle = speedLimitStyle
        return newSelf
    }
}
