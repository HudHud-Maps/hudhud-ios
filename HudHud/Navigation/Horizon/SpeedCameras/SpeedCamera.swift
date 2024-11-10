//
//  SpeedCamera.swift
//  HudHud
//
//  Created by Ali Hilal on 04/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation

struct SpeedCamera: Equatable, Hashable {

    // MARK: Properties

    let id: String
    let speedLimit: Measurement<UnitSpeed>
    let type: SpeedCameraType
    let direction: CameraDirection
    let captureRange: Measurement<UnitLength>
    let location: CLLocationCoordinate2D

    // MARK: Computed Properties

    var alertDistance: Measurement<UnitLength> {
        switch self.type {
        case .averageSpeed:
            return .kilometers(2) // usally 2km for average speed zones. check it with BE
        case .combined:
            return .kilometers(1.5) // 1.5km for combined cameras
        case .redLight:
            return .meters(500) // 500m for red light cameras
        default:
            return .kilometers(1) // 1km for standard speed cameras
        }
    }

    var isActive: Bool {
        switch self.type {
        case .mobile:
            return true // This should be determined by backend data
        default:
            return true
        }
    }
}
