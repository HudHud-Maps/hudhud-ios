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
    let location: CLLocationCoordinate2D
    var heading: CGFloat
}

extension StreetViewPoint {

    var feature: MLNPointFeature {
        MLNPointFeature(coordinate: self.location) { feature in
            feature.attributes["heading"] = self.heading
        }
    }
}
