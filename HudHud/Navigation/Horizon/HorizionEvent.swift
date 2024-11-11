//
//  HorizionEvent.swift
//  HudHud
//
//  Created by Ali Hilal on 06/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

enum HorizionEvent: Equatable {
    case approachingSpeedCamera(SpeedCamera, distance: Measurement<UnitLength>)
    case passedSpeedCamera(SpeedCamera)
    case enteredSpeedZone(limit: Measurement<UnitSpeed>)
    case exitedSpeedZone
    case approachingTrafficIncident(TrafficIncident, distance: Measurement<UnitLength>)
    case passedTrafficIncident(TrafficIncident)
}
