//
//  RoutePlanningError.swift
//  HudHud
//
//  Created by Patrick Kladek on 07.11.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import FerrostarCoreFFI
import Foundation

enum RoutePlanningError: LocalizedError {
    case locationNotEnabled
    case errorFetchingRoute
}
