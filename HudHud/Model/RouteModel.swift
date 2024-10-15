//
//  RouteModel.swift
//  HudHud
//
//  Created by Ali on 13/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import FerrostarCoreFFI
import Foundation

struct RouteModel: Identifiable, Equatable {

    // MARK: Properties

    let route: Route
    var isSelected: Bool

    // MARK: Computed Properties

    var id: Int { self.route.id }
}
