//
//  RouteStyleLayer.swift
//  HudHud
//
//  Created by Ali Hilal on 03.11.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import UIKit

// MARK: - RouteStyle

public protocol RouteStyle {
    var color: UIColor { get }
    var casingColor: UIColor? { get }

    var lineCap: LineCap { get }
    var lineJoin: LineJoin { get }
}

// MARK: - ActiveRouteStyle

public struct ActiveRouteStyle: RouteStyle {

    // MARK: Properties

    public let color: UIColor = .systemBlue
    public let casingColor: UIColor? = .white
    public let lineCap: LineCap = .round
    public let lineJoin: LineJoin = .round

    // MARK: Lifecycle

    public init() {}
}

// MARK: - TravelledRouteStyle

public struct TravelledRouteStyle: RouteStyle {

    // MARK: Properties

    public var color: UIColor = .systemBlue.withAlphaComponent(0.5)
    public var casingColor: UIColor? = .white.withAlphaComponent(0.5)
    public let lineCap: LineCap = .round
    public let lineJoin: LineJoin = .round

    // MARK: Lifecycle

    public init() {}
}

// MARK: - RouteStyleLayer

public struct RouteStyleLayer: StyleLayerCollection {

    // MARK: Properties

    private let polyline: MLNPolyline
    private let identifier: String
    private let style: RouteStyle

    // MARK: Computed Properties

    public var layers: [StyleLayerDefinition] {
        let source = ShapeSource(identifier: "\(identifier)-source") {
            self.polyline
        }

        if let casingColor = style.casingColor {
            LineStyleLayer(identifier: "\(self.identifier)-casing", source: source)
                .lineCap(self.style.lineCap)
                .lineJoin(self.style.lineJoin)
                .lineColor(casingColor)
                .lineWidth(interpolatedBy: .zoomLevel,
                           curveType: .exponential,
                           parameters: NSExpression(forConstantValue: 1.5),
                           stops: NSExpression(forConstantValue: [14: 6, 18: 24]))
        }

        LineStyleLayer(identifier: "\(self.identifier)-polyline", source: source)
            .lineCap(self.style.lineCap)
            .lineJoin(self.style.lineJoin)
            .lineColor(self.style.color)
            .lineWidth(interpolatedBy: .zoomLevel,
                       curveType: .exponential,
                       parameters: NSExpression(forConstantValue: 1.5),
                       stops: NSExpression(forConstantValue: [14: 3, 18: 16]))
    }

    // MARK: Lifecycle

    public init(polyline: MLNPolyline, identifier: String, style: RouteStyle = ActiveRouteStyle()) {
        self.polyline = polyline
        self.identifier = identifier
        self.style = style
    }

}
