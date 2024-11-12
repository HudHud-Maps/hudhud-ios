//
//  CameraDirection.swift
//  HudHud
//
//  Created by Ali Hilal on 04/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation

enum CameraDirection: Equatable, Hashable {
    /// xaptures vehicles moving away from camera
    case forward

    /// captures vehicles approaching camera
    case backward

    /// captures vehicles in both directions/
    case both

    /// for cameras monitoring specific road direction
    case specific(bearing: CLLocationDirection)
}
