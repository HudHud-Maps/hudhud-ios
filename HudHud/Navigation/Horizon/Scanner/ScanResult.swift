//
//  ScanResult.swift
//  HudHud
//
//  Created by Ali Hilal on 06/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

struct ScanResult: Equatable {
    let detectedFeatures: [HorizonFeature]
    let approachingFeatures: [FeatureDistance]
    let exitedFeatures: [HorizonFeature]
}
