//
//  TripAlertType.swift
//  HudHud
//
//  Created by Ali Hilal on 09/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import SwiftUI

// MARK: - TripAlertType

enum TripAlertType: Equatable {
    case speedCamera(SpeedCamera)
    case carAccident(TrafficIncident)

    // MARK: Computed Properties

    var icon: Image {
        switch self {
        case .speedCamera: return Image(.speedCamIcon)
        case .carAccident: return Image(.carAccidentWithoutBg)
        }
    }

    var color: Color {
        switch self {
        case .speedCamera: return .red
        case .carAccident: return .red
        }
    }

    var title: String {
        switch self {
        case .speedCamera: return "Speed Camera"
        case .carAccident: return "Car Accident"
        }
    }

    var coordinate: CLLocationCoordinate2D {
        switch self {
        case let .speedCamera(speedCamera): return speedCamera.location
        case let .carAccident(trafficIncident): return trafficIncident.location
        }
    }

    var mapIcon: UIImage {
        switch self {
        case let .speedCamera(camera):
            return camera.icon
        case .carAccident:
            return UIImage(resource: .carAccident)
        }
    }
}

extension SpeedCamera {
    var icon: UIImage {
        switch self.type {
        case .fixed, .mobile, .averageSpeed, .combined:
            return UIImage(resource: .speedCam120)
        case .redLight:
            return UIImage(resource: .redLighSpeedCamera)
        }
    }

}
