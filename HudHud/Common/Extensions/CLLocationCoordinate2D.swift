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
        return CLLocation(coordinate: coordinate, altitude: altitude, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: .now)
    }

    static let riyadh: CLLocation = .coordinate(.riyadh, altitude: 600)
    static let theGarage: CLLocation = .coordinate(.theGarage, altitude: 647)
    static let jeddah: CLLocation = .coordinate(.jeddah, altitude: 12)
}

extension CLLocationCoordinate2D {

    static let zero = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    static let riyadh = CLLocationCoordinate2D(latitude: 24.65333, longitude: 46.71526)
    static let theGarage = CLLocationCoordinate2D(latitude: 24.7193306, longitude: 46.6468)
    static let jeddah = CLLocationCoordinate2D(latitude: 21.54238, longitude: 39.19797)
}

extension CLLocationCoordinate2D {

    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: latitude, longitude: longitude)
        let to = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return from.distance(from: to)
    }
}

extension CLLocationDirection {

    func isClose(to direction: CLLocationDirection, tolerance: CLLocationDirection = 45) -> Bool {
        let diff = abs(self - direction)
        return diff <= tolerance || diff >= (360 - tolerance)
    }
}

extension CLLocationCoordinate2D {

    func bearing(to coordinate: CLLocationCoordinate2D) -> CLLocationDirection {
        let lat1 = self.latitude.degreesToRadians
        let lon1 = self.longitude.degreesToRadians
        let lat2 = coordinate.latitude.degreesToRadians
        let lon2 = coordinate.longitude.degreesToRadians

        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)

        return (radiansBearing.radiansToDegrees + 360).truncatingRemainder(dividingBy: 360)
    }
}

extension Double {

    var degreesToRadians: Double { self * .pi / 180 }
    var radiansToDegrees: Double { self * 180 / .pi }
}
