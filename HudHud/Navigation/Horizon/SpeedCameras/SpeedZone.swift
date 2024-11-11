//
//  SpeedZone.swift
//  HudHud
//
//  Created by Ali Hilal on 04/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation

struct SpeedZone: Equatable {
    let id: UUID
    let location: CLLocationCoordinate2D
    let limit: Measurement<UnitSpeed>
}
