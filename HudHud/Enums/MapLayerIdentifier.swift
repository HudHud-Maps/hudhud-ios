//
//  MapLayerIdentifier.swift
//  HudHud
//
//  Created by Alaa . on 02/05/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

enum MapLayerIdentifier {

    // MARK: Static Properties

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
    static let hudhudPOIPrefix = "hpoi_"
    static let restaurants = "\(Self.hudhudPOIPrefix)resturant"
    static let shops = "\(Self.hudhudPOIPrefix)shop"
    static let streetView = "\(Self.hudhudPOIPrefix)sv"

    static let customPOI = "patPOI"

    static let routePrefix = "route"
    static let congestionPrefix = "congestion"

    // the new POI layer identifier
    static let poiLevel1 = "poi-level-1"

    // MARK: Static Functions

    static func routeInner(_ index: Int) -> String { "\(self.routePrefix)-inner-\(index)" }
    static func routeCasing(_ index: Int) -> String { "\(self.routePrefix)-casing-\(index)" }
    static func congestion(_ level: String, index: Int) -> String { "\(self.congestionPrefix)-\(level)-\(index)" }
}
