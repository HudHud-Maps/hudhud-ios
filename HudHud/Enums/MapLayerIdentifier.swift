//
//  MapLayerIdentifier.swift
//  HudHud
//
//  Created by Alaa . on 02/05/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

enum MapLayerIdentifier {
    static var routeLineCasing = "routeLineCasing"
    static var routeLineInner = "routeLineInner"
    static var simpleCirclesRoute = "simpleCirclesRoute"
    static var simpleSymbolsRoute = "simpleSymbolsRoute"
    static var simpleCirclesClustered = "simpleCirclesClustered"
    static var simpleSymbolsClustered = "simpleSymbolsClustered"
    static var simpleCircles = "simpleCircles"
    static let selectedCircle = "selectedCircle"
    static let selectedCircleIcon = "selectedCircleIcon"
    static var simpleSymbols = "simpleSymbols"

    // layers that our backend put on our map
    // we use them to query metadata related to points from our map
    static let restaurants = "hpoi_resturant"
    static let shops = "hpoi_shop"
    static let streetView = "hpoi_sv"
    static let patPOI = "patPOI"
}
