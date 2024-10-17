//
//  NavigationAnnotation.swift
//  HudHud
//
//  Created by Naif Alrashed on 17/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import FerrostarCore
import Foundation

struct NavigationAnnotation: Decodable {

    // MARK: Nested Types

    enum CodingKeys: String, CodingKey {
        case maxSpeed = "maxspeed"
    }

    // MARK: Properties

    let maxSpeed: MaxSpeed
}
