//
//  SpeedCameraType.swift
//  HudHud
//
//  Created by Ali Hilal on 04/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

enum SpeedCameraType: Hashable, Equatable {
    case fixed
    case mobile
    case redLight
    case averageSpeed(zoneLength: Measurement<UnitLength>)
    case combined(types: Set<SpeedCameraType>)
}
