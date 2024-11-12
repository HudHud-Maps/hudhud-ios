//
//  EarthConstants.swift
//  HudHud
//
//  Created by Ali Hilal on 12/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

enum EarthConstants {
    static let a = 6_378_137.0 // semi-major axis
    static let f = 1.0 / 298.257223563 // flattening
    static let b = a * (1.0 - f) // semi-minor axis
    static let asqr = a * a
    static let bsqr = b * b
    static let e = sqrt((asqr - bsqr) / asqr) // first eccentricity
    static let eprime = sqrt((asqr - bsqr) / bsqr) // second eccentricity
}
