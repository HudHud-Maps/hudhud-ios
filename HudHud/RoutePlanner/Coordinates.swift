//
//  Coordinates.swift
//  HudHud
//
//  Created by Patrick Kladek on 07.11.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation

// MARK: - Coordinates

struct Coordinates: Hashable {

    // MARK: Properties

    let latitude: Double
    let longitude: Double

    // MARK: Computed Properties

    var clLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }

    // MARK: Lifecycle

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    init(_ coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
}
