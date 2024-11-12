//
//  ExactRoutePosition.swift
//  HudHud
//
//  Created by Ali Hilal on 12/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation

// MARK: - ExactRoutePosition

struct ExactRoutePosition {
    /// Actual coordinate index in the route
    let coordinateIndex: Int

    /// Next coordinate index
    let nextCoordinateIndex: Int

    let segmentIndex: Int

    /// 1:1 mapping to the same coordinate on the route
    let exactCoordinate: CLLocationCoordinate2D

    let distanceFromStart: Double

    let distanceFromSegmentStart: Double

    let percentageAlongSegment: Double
}

extension ExactRoutePosition {
    func isBefore(_ other: ExactRoutePosition) -> Bool {
        if self.coordinateIndex == other.coordinateIndex {
            return self.distanceFromSegmentStart < other.distanceFromSegmentStart
        }
        return self.coordinateIndex < other.coordinateIndex
    }

    func isAfter(_ other: ExactRoutePosition) -> Bool {
        if self.coordinateIndex == other.coordinateIndex {
            return self.distanceFromSegmentStart > other.distanceFromSegmentStart
        }
        return self.coordinateIndex > other.coordinateIndex
    }
}
