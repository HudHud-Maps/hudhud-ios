//
//  CongestionSegment.swift
//  HudHud
//
//  Created by Ali Hilal on 17/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation

struct CongestionSegment {
    let level: String
    let startIndex: Int
    let endIndex: Int
    let points: [CLLocationCoordinate2D]
}
