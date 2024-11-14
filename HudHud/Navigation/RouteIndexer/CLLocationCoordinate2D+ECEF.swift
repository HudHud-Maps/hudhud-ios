//
//  CLLocationCoordinate2D+ECEF.swift
//  HudHud
//
//  Created by Ali Hilal on 12/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation

// swiftlint:disable large_tuple
func ECEFToLatLng(_ point: (x: Double, y: Double, z: Double)) -> CLLocationCoordinate2D {
    let xCoord = point.x
    let yCoord = point.y
    let zCoord = point.z

    let horizontalDistance = sqrt(xCoord * xCoord + yCoord * yCoord)
    let theta = atan((zCoord * EarthConstants.a) / (horizontalDistance * EarthConstants.b))
    let sinTheta = sin(theta)
    let cosTheta = cos(theta)

    let numerator = zCoord + EarthConstants.eprime * EarthConstants.eprime * EarthConstants.b * pow(sinTheta, 3)
    let denominator = horizontalDistance - EarthConstants.e * EarthConstants.e * EarthConstants.a * pow(cosTheta, 3)

    var latitude = atan(numerator / denominator)
    var longitude = atan2(yCoord, xCoord)

    latitude = latitude * 180.0 / .pi
    longitude = longitude * 180.0 / .pi

    return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
}

extension CLLocationCoordinate2D {
    func toECEF() -> (x: Double, y: Double, z: Double) {
        let latitudeRadians = latitude * .pi / 180.0
        let longitudeRadians = longitude * .pi / 180.0
        let altitude = 0.0

        let normalRadius = EarthConstants.a / sqrt(1.0 - EarthConstants.e * EarthConstants.e * pow(sin(latitudeRadians), 2))

        let xCoord = (normalRadius + altitude) * cos(latitudeRadians) * cos(longitudeRadians)
        let yCoord = (normalRadius + altitude) * cos(latitudeRadians) * sin(longitudeRadians)
        let zCoord = ((EarthConstants.bsqr / EarthConstants.asqr) * normalRadius + altitude) * sin(latitudeRadians)

        return (xCoord, yCoord, zCoord)
    }
}

// swiftlint:enable large_tuple
