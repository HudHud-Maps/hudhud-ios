//
//  DirectionModePickerData.swift
//  HudHud
//
//  Created by Alaa . on 04/03/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SFSafeSymbols

// MARK: - DirectionModePickerData

struct DirectionModePickerData: Identifiable, Equatable {

    // MARK: Properties

    let mode: DirectionMode
    let duration: TimeInterval

    // MARK: Computed Properties

    var id: DirectionMode { self.mode }
}

// MARK: - DirectionMode

enum DirectionMode: Identifiable {

    case car
    case walk
    case bus
    case metro
    case bicycle

    // MARK: Computed Properties

    var id: Self {
        return self
    }

    var iconName: SFSymbol {
        switch self {
        case .car: return .car
        case .walk: return .figureWalk
        case .bus: return .bus
        case .metro: return .trainSideFrontCar
        case .bicycle: return .bicycle
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .car: return "car"
        case .walk: return "walk"
        case .bus: return "bus"
        case .metro: return "metro"
        case .bicycle: return "bicycle"
        }
    }
}
