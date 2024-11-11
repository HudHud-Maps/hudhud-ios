//
//  RouteGeometryCalculator.swift
//  HudHud
//
//  Created by Ali Hilal on 06/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation

// MARK: - RouteGeometryCalculator

final class RouteGeometryCalculator {

    // MARK: Nested Types

    struct RouteSegment {
        let startIndex: Int
        let endIndex: Int
        let startPoint: CLLocationCoordinate2D
        let endPoint: CLLocationCoordinate2D
        let distance: CLLocationDistance
        let bearing: Double
    }

    // MARK: Properties

    private var geometry: [CLLocationCoordinate2D]
    private var cachedSegments: [RouteSegment] = []
    private var lastCalculatedDistances: [String: CLLocationDistance] = [:]

    private var previousPosition: RoutePosition?

    // MARK: Lifecycle

    init(geometry: [CLLocationCoordinate2D]) {
        self.geometry = geometry
        self.updateSegmentCache()
    }

    // MARK: Functions

    func update(with geometry: [CLLocationCoordinate2D]) {
        self.geometry = geometry
        self.updateSegmentCache()
        self.lastCalculatedDistances.removeAll()
        self.previousPosition = nil
    }

    func findPosition(for point: CLLocationCoordinate2D) -> RoutePosition {
        guard let lastPosition = previousPosition else {
            return self.findClosestSegment(for: point)
        }

        let searchStart = max(0, lastPosition.index - 1)
        let searchEnd = min(geometry.count - 2, lastPosition.index + 1)

        var bestPosition: RoutePosition?
        var minDistance = Double.infinity

        for i in searchStart ... searchEnd {
            let start = self.geometry[i]
            let end = self.geometry[i + 1]

            let (distance, projected) = self.distanceToLineSegment(point: point, start: start, end: end)

            if distance < minDistance {
                minDistance = distance
                bestPosition = RoutePosition(index: i, projectedDistance: projected)
            }
        }

        if let position = bestPosition, minDistance < LocationConstants.significantDistanceChange {
            self.previousPosition = position
            return position
        }

        let newPosition = self.findClosestSegment(for: point)
        self.previousPosition = newPosition
        return newPosition
    }

    func calculateDistanceAlongRoute(from userLocation: CLLocationCoordinate2D,
                                     to featureLocation: CLLocationCoordinate2D,
                                     featureId: String) -> CLLocationDistance {
        let userPosition = self.findPosition(for: userLocation)
        let featurePosition = self.findPosition(for: featureLocation)

        if featurePosition.isBefore(userPosition) {
            return .infinity
        }

        var distance: CLLocationDistance = 0

        if userPosition.index == featurePosition.index {
            let segmentDistance = featurePosition.projectedDistance - userPosition.projectedDistance
            if segmentDistance < 0 {
                return .infinity
            }
            distance = segmentDistance
        } else {
            if userPosition.index < self.cachedSegments.count {
                let userSegment = self.cachedSegments[userPosition.index]
                distance += userSegment.distance - userPosition.projectedDistance
            }

            for i in (userPosition.index + 1) ..< featurePosition.index {
                guard i < self.cachedSegments.count else { break }
                distance += self.cachedSegments[i].distance
            }

            distance += featurePosition.projectedDistance
        }

        if let lastDistance = lastCalculatedDistances[featureId] {
            let change = abs(distance - lastDistance)
            if change > 10 {
                distance = lastDistance + (distance > lastDistance ? 10 : -10)
            }
        }

        self.lastCalculatedDistances[featureId] = distance
        return distance
    }

    func isMovingTowardsFeature(userLocation: CLLocationCoordinate2D,
                                featureLocation: CLLocationCoordinate2D,
                                userCourse _: CLLocationDirection) -> Bool {
        let featurePosition = self.findPosition(for: featureLocation)
        let userPosition = self.findPosition(for: userLocation)

        if userPosition.index == featurePosition.index {
            return userPosition.projectedDistance < featurePosition.projectedDistance
        }

        return userPosition.isBefore(featurePosition)
    }
}

private extension RouteGeometryCalculator {

    func findClosestSegment(for point: CLLocationCoordinate2D) -> RoutePosition {
        var minDistance = Double.infinity
        var bestPosition = RoutePosition(index: 0, projectedDistance: 0)

        for i in 0 ..< (self.geometry.count - 1) {
            let start = self.geometry[i]
            let end = self.geometry[i + 1]

            let (distance, projected) = self.distanceToLineSegment(point: point, start: start, end: end)

            if distance < minDistance {
                minDistance = distance
                bestPosition = RoutePosition(index: i, projectedDistance: projected)
            }
        }

        return bestPosition
    }

    // MARK: - Private Methods

    func updateSegmentCache() {
        guard !self.geometry.isEmpty else {
            return
        }
        self.cachedSegments = []
        for i in 0 ..< (self.geometry.count - 1) {
            let start = self.geometry[i]
            let end = self.geometry[i + 1]
            let segment = RouteSegment(startIndex: i,
                                       endIndex: i + 1,
                                       startPoint: start,
                                       endPoint: end,
                                       distance: start.distance(to: end),
                                       bearing: start.bearing(to: end))
            self.cachedSegments.append(segment)
        }
    }

    func getUpcomingSegments(from index: Int, count: Int) -> [RouteSegment] {
        guard index < self.cachedSegments.count else { return [] }
        let endIndex = min(index + count, self.cachedSegments.count)
        return Array(self.cachedSegments[index ..< endIndex])
    }

    func calculateAverageBearing(segments: [RouteSegment]) -> Double {
        guard !segments.isEmpty else { return 0 }
        let totalBearing = segments.reduce(0.0) { $0 + $1.bearing }
        return totalBearing / Double(segments.count)
    }

    func distanceToLineSegment(point: CLLocationCoordinate2D,
                               start: CLLocationCoordinate2D,
                               end: CLLocationCoordinate2D) -> (distance: CLLocationDistance, projectedDistance: CLLocationDistance) {
        let startToPoint = CLLocation(latitude: point.latitude, longitude: point.longitude)
            .distance(from: CLLocation(latitude: start.latitude, longitude: start.longitude))
        let startToEnd = CLLocation(latitude: start.latitude, longitude: start.longitude)
            .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude))

        if startToEnd == 0 {
            return (startToPoint, 0)
        }

        let bearing = start.bearing(to: end)
        let pointBearing = start.bearing(to: point)
        let pointDistance = start.distance(to: point)

        let ex = startToEnd * cos(bearing * .pi / 180.0)
        let ey = startToEnd * sin(bearing * .pi / 180.0)
        let px = pointDistance * cos(pointBearing * .pi / 180.0)
        let py = pointDistance * sin(pointBearing * .pi / 180.0)

        let dot = px * ex + py * ey
        let t = max(0, min(1, dot / (startToEnd * startToEnd)))

        let projectedPoint = self.interpolate(start: start, end: end, t: t)

        let distance = point.distance(to: projectedPoint)
        let projectedDistance = start.distance(to: projectedPoint)

        return (distance, projectedDistance)
    }

    func dot(_ point: CLLocationCoordinate2D,
             _ start: CLLocationCoordinate2D,
             _ end: CLLocationCoordinate2D) -> Double {
        let px = point.longitude - start.longitude
        let py = point.latitude - start.latitude
        let ex = end.longitude - start.longitude
        let ey = end.latitude - start.latitude
        return px * ex + py * ey
    }

    func interpolate(start: CLLocationCoordinate2D,
                     end: CLLocationCoordinate2D,
                     t: Double) -> CLLocationCoordinate2D {
        let lat = start.latitude + (end.latitude - start.latitude) * t
        let lon = start.longitude + (end.longitude - start.longitude) * t
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}
