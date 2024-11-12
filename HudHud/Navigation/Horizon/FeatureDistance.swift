//
//  FeatureDistance.swift
//  HudHud
//
//  Created by Ali Hilal on 06/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation

struct FeatureDistance: Equatable {
    let feature: HorizonFeature
    let distance: Measurement<UnitLength>
}
