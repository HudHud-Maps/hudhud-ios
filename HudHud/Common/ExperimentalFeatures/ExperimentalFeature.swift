//
//  ExperimentalFeature.swift
//  HudHud
//
//  Created by Ali Hilal on 07/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

enum ExperimentalFeature: String, CaseIterable, Identifiable {
    case safetyCamsAndAlerts = "Safetry Cams & Alerts"
    case enableNewRoutePlanner = "Enable New Route Planner"

    // MARK: Computed Properties

    var id: String { rawValue }
}
