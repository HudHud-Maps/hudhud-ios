//
//  TripAlertType.swift
//  HudHud
//
//  Created by Ali Hilal on 09/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import SwiftUI

enum TripAlertType: Equatable {
    case speedCamera(SpeedCamera)
    case carAccident(TrafficIncident)

    // MARK: Computed Properties

    var icon: String {
        switch self {
        case .speedCamera: return "camera.fill"
        case .carAccident: return "car.fill"
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
}
