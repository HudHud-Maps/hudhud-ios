//
//  NavigationEvent.swift
//  HudHud
//
//  Created by Ali Hilal on 17/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import FerrostarCore
import FerrostarCoreFFI

enum NavigationEvent {
    case idle
    case devaited(RouteDeviation)
    case progressing(TripProgress)
    case visualInstruction(VisualInstruction?)
    case spokenInstruction(SpokenInstruction)
    case currentPositionAnnotation(ValhallaOsrmAnnotation?)
    case arrived
}
