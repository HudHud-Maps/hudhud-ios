//
//  StreetViewPoint.swift
//  HudHud
//
//  Created by Patrick Kladek on 02.04.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation
import MapLibre

// MARK: - StreetViewPoint

struct StreetViewPoint: Equatable {
    let coordinates: CLLocationCoordinate2D
    var heading: Float
}

extension StreetViewPoint {

    var feature: MLNPointFeature {
        MLNPointFeature(coordinate: self.coordinates) { feature in
            feature.attributes["heading"] = self.heading
        }
    }
}
