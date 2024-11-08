//
//  CLLocationCoordinate2D.swift
//  HudHud
//
//  Created by Patrick Kladek on 02.04.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation

extension CLLocation {
    static func coordinate(_ coordinate: CLLocationCoordinate2D, altitude: CLLocationDistance = 0) -> CLLocation {
        return CLLocation(coordinate: coordinate, altitude: altitude, horizontalAccuracy: 1, verticalAccuracy: 1, timestamp: .now)
    }

    static let riyadh: CLLocation = .coordinate(.riyadh, altitude: 600)
    static let jeddah: CLLocation = .coordinate(.jeddah, altitude: 12)
}

extension CLLocationCoordinate2D {
    static let zero = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    static let riyadh = CLLocationCoordinate2D(latitude: 24.65333, longitude: 46.71526)
    static let jeddah = CLLocationCoordinate2D(latitude: 21.54238, longitude: 39.19797)

    // Used for testing StreetView
    static let image1 = CLLocationCoordinate2D(latitude: 21.54238, longitude: 39.19797)
    static let image2 = CLLocationCoordinate2D(latitude: 25, longitude: 46)
    static let image3 = CLLocationCoordinate2D(latitude: 20, longitude: 40)
}

extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: latitude, longitude: longitude)
        let to = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return from.distance(from: to)
    }
}
