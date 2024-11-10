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
    private enum SpeedBracket: Int {
        case up30 = 30
        case up50 = 50
        case up70 = 70
        case up90 = 90
        case up120 = 120
        case above120 = 999

        // MARK: Static Functions

        static func bracket(for speed: Int) -> SpeedBracket {
            let brackets = [up30, up50, up70, up90, up120, above120]
            return brackets.first(where: { $0.rawValue >= speed }) ?? .above120
        }
    }

    private struct IconKey: Hashable {
        let type: SpeedCameraType
        let speedBracket: SpeedBracket
    }

    private static let iconMapping: [IconKey: ImageResource] = [
        // fixed cameras
        IconKey(type: .fixed, speedBracket: .up30): .speedCam120,
        IconKey(type: .fixed, speedBracket: .up50): .speedCam120,
        IconKey(type: .fixed, speedBracket: .up70): .speedCam120,
        IconKey(type: .fixed, speedBracket: .up90): .speedCam120,
        IconKey(type: .fixed, speedBracket: .up120): .speedCam120,
        IconKey(type: .fixed, speedBracket: .above120): .speedCam120,

        // mobile cameras
        IconKey(type: .mobile, speedBracket: .up30): .speedCam120,
        IconKey(type: .mobile, speedBracket: .up50): .speedCam120,
        IconKey(type: .mobile, speedBracket: .up70): .speedCam120,
        IconKey(type: .mobile, speedBracket: .up90): .speedCam120,
        IconKey(type: .mobile, speedBracket: .up120): .speedCam120,
        IconKey(type: .mobile, speedBracket: .above120): .speedCam120,

        // red light cameras (speed independent)
        IconKey(type: .redLight, speedBracket: .up30): .redLighSpeedCamera,
        IconKey(type: .redLight, speedBracket: .up50): .redLighSpeedCamera,
        IconKey(type: .redLight, speedBracket: .up70): .redLighSpeedCamera,
        IconKey(type: .redLight, speedBracket: .up90): .redLighSpeedCamera,
        IconKey(type: .redLight, speedBracket: .up120): .redLighSpeedCamera,
        IconKey(type: .redLight, speedBracket: .above120): .redLighSpeedCamera
    ]

    var icon: UIImage {
        let speed = self.speedLimit.kilometersPerHour
        let bracket = SpeedBracket.bracket(for: Int(speed))
        let key = IconKey(type: self.type, speedBracket: bracket)

        let resource = Self.iconMapping[key] ?? .speedCam120
        return UIImage(resource: resource)
    }
}
