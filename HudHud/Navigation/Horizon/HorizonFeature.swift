//
//  HorizonFeature.swift
//  HudHud
//
//  Created by Ali Hilal on 06/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation

struct HorizonFeature: Equatable {

    // MARK: Nested Types

    //    let metadata: FeatureMetadata

    enum FeatureType: Equatable {
        case speedCamera(SpeedCamera)
        case speedZone(SpeedZone)
        case trafficIncident(TrafficIncident)
    }

    // MARK: Properties

    let id: String
    let type: FeatureType
    let coordinate: CLLocationCoordinate2D
}
