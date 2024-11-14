//
//  RTreeNode.swift
//  HudHud
//
//  Created by Ali Hilal on 11/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation

// MARK: - RTreeNode

final class RTreeNode {

    // MARK: Properties

    var bounds: BoundingBox
    var children: [RTreeNode]?
    var points: [RoutePoint]?
    let maxEntries: Int = 8

    // MARK: Lifecycle

    init(bounds: BoundingBox) {
        self.bounds = bounds
    }
}

extension RTreeNode {

    struct RoutePoint: Hashable {
        let index: Int
        let coordinate: CLLocationCoordinate2D
    }

    struct BoundingBox {

        // MARK: Static Computed Properties

        static var infinite: BoundingBox {
            return BoundingBox(minLat: Double.infinity,
                               minLon: Double.infinity,
                               maxLat: -Double.infinity,
                               maxLon: -Double.infinity)
        }

        // MARK: Properties

        var minLat: Double
        var minLon: Double
        var maxLat: Double
        var maxLon: Double

        // MARK: Functions

        func contains(_ coord: CLLocationCoordinate2D) -> Bool {
            return coord.latitude >= self.minLat && coord.latitude <= self.maxLat &&
                coord.longitude >= self.minLon && coord.longitude <= self.maxLon
        }

        func intersects(_ other: BoundingBox) -> Bool {
            return !(self.minLat > other.maxLat || self.maxLat < other.minLat ||
                self.minLon > other.maxLon || self.maxLon < other.minLon)
        }
    }
}
