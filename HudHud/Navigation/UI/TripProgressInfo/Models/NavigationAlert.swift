//
//  NavigationAlert.swift
//  HudHud
//
//  Created by Ali Hilal on 07/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

struct NavigationAlert: Equatable {
    let id: String
    let progress: CGFloat
    let alertType: TripAlertType
    let alertDistance: Int
}
