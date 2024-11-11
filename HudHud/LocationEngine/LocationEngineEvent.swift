//
//  LocationEngineEvent.swift
//  HudHud
//
//  Created by Ali Hilal on 04/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation

// MARK: - LocationEngineEvent

enum LocationEngineEvent: Equatable {
    case locationUpdated(CLLocation)
    case modeChanged(LocationMode)
    case providerChanged(LocationProviderType)
    //    case error(Error)

}

extension LocationEngineEvent {
    static func == (lhs: LocationEngineEvent, rhs: LocationEngineEvent) -> Bool {
        switch (lhs, rhs) {
        case let (.locationUpdated(loc1), .locationUpdated(loc2)):
            return loc1.coordinate.latitude == loc2.coordinate.latitude &&
                loc1.coordinate.longitude == loc2.coordinate.longitude &&
                loc1.horizontalAccuracy == loc2.horizontalAccuracy &&
                loc1.course == loc2.course &&
                loc1.speed == loc2.speed

        case let (.modeChanged(mode1), .modeChanged(mode2)):
            return mode1 == mode2

        case let (.providerChanged(type1), .providerChanged(type2)):
            return type1 == type2

        default:
            return false
        }
    }
}
