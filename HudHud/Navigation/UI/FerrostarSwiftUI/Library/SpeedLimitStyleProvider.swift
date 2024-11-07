//
//  SpeedLimitStyleProvider.swift
//  HudHud
//
//  Created by Ali Hilal on 03.11.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

// MARK: - SpeedLimitStyleProviding

/// Build a data provider that tells the UI whether to prefer a US style (MUTCD) or Vienna style speed limit sign.
protocol SpeedLimitStyleProviding {
    func useUSStyle() -> Bool
}

// MARK: - USSpeedLimitStyleProvider

// MUTCD Signage Regions: https://en.wikipedia.org/wiki/Manual_on_Uniform_Traffic_Control_Devices
//    US, Canada, Mexico, Belize, Argentina, Bolivia, Brazil, Colombia, Equador, Guyana
//    Paraguay, Peru, Venezuela, Austrialia, Thailand.
// Region Codes: https://en.wikipedia.org/wiki/IETF_language_tag

/// Always prefer US Style (MUTCD)
class USSpeedLimitStyleProvider: SpeedLimitStyleProviding {
    func useUSStyle() -> Bool {
        true
    }
}

// MARK: - SpeedLimitFixedToViennaConventionStyle

/// Always prefer Vienna Style
class SpeedLimitFixedToViennaConventionStyle: SpeedLimitStyleProviding {
    func useUSStyle() -> Bool {
        false
    }
}
