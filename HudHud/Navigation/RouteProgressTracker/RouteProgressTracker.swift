//
//  RouteProgressTracker.swift
//  HudHud
//
//  Created by Ali Hilal on 12/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation

// MARK: - RouteProgressTracker

final class RouteProgressTracker {

    // MARK: Properties

    private let spatialIndex: RouteGeometrySpatialIndex
    private var routeCoordinates: [CLLocationCoordinate2D]
    private var totalDistance: CLLocationDistance
    private var isActive: Bool

    // MARK: Lifecycle

    init(coordinates: [CLLocationCoordinate2D] = [], totalDistance: CLLocationDistance = .zero) {
        self.routeCoordinates = coordinates
        self.totalDistance = totalDistance
        self.spatialIndex = RouteGeometrySpatialIndex(coordinates: coordinates)
        self.isActive = !coordinates.isEmpty
    }

    // MARK: Functions

    func setRoute(coordinates: [CLLocationCoordinate2D], totalDistance: CLLocationDistance) {
        self.routeCoordinates = coordinates
        self.totalDistance = totalDistance
        self.spatialIndex.reindex(using: coordinates)
        self.isActive = !coordinates.isEmpty
    }

    func calcualteProgress(
        from location: CLLocation,
        and distanceFromStart: CLLocationDistance
    ) -> PathTraversalProgress {
        guard self.isActive else {
            return PathTraversalProgress(
                totalDistance: 0,
                drivenDistance: 0,
                lastPosition: .empty,
                drivenCoordinates: [],
                remainingCoordinates: []
            )
        }

        let currentPosition = self.spatialIndex.findExactPosition(for: location.coordinate)
        let (driven, remaining) = splitCoordinates(
            at: currentPosition,
            from: routeCoordinates
        )

        return PathTraversalProgress(
            totalDistance: self.totalDistance,
            drivenDistance: distanceFromStart,
            lastPosition: currentPosition,
            drivenCoordinates: driven,
            remainingCoordinates: remaining
        )
    }

    func flush() {
        self.routeCoordinates = []
        self.totalDistance = 0
        self.spatialIndex.flush()
        self.isActive = false
    }
}

private extension RouteProgressTracker {

    func splitCoordinates(
        at position: ExactRoutePosition,
        from coordinates: [CLLocationCoordinate2D]
    ) -> (
        driven: [CLLocationCoordinate2D],
        remaining: [CLLocationCoordinate2D]
    ) {
        guard position.index < coordinates.count else {
            return (coordinates, [])
        }

        let driven = position.index > 0 ? Array(coordinates[0 ... (position.index - 1)]) : []

        if position.index + 1 < coordinates.count {
            let start = coordinates[position.index]
            let end = coordinates[position.index + 1]
            let segment = CLLocation(latitude: start.latitude, longitude: start.longitude)
                .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude))

            let ratio = max(0, min(1, (position.distanceFromSegmentStart - 3) / segment))

            let currentPoint = self.spatialIndex.interpolate(
                start: start,
                end: end,
                t: ratio
            )

            let beforeRatio = max(0, (position.distanceFromSegmentStart - 6) / segment)
            let beforePoint = self.spatialIndex.interpolate(
                start: start,
                end: end,
                t: beforeRatio
            )
            return (driven + [start, beforePoint],
                    [currentPoint] + Array(coordinates[(position.index + 1)...]))
        }

        return (driven, Array(coordinates[position.index...]))
    }
}

private extension ExactRoutePosition {
    var index: Int {
        coordinateIndex
    }
}
