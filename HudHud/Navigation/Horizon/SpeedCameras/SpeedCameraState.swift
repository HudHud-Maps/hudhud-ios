//
//  SpeedCameraState.swift
//  HudHud
//
//  Created by Ali Hilal on 04/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation

struct SpeedCameraState {
    let camera: SpeedCamera
    let distance: Measurement<UnitLength>
    let approachZone: CLLocationDistance
    let alertZone: CLLocationDistance
}
