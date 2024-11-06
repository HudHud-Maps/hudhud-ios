//
//  RouteGeometryCalculator.swift
//  HudHud
//
//  Created by Ali Hilal on 06/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation

final class RouteGeometryCalculator {

    // MARK: Properties

    private var geometry: [CLLocationCoordinate2D]

    // MARK: Lifecycle

    init(geometry: [CLLocationCoordinate2D]) {
        self.geometry = geometry
    }

    // MARK: Functions

    func update(with geometry: [CLLocationCoordinate2D]) {
        self.geometry = geometry
    }

    func findPosition(for point: CLLocationCoordinate2D) -> RoutePosition {
        var closestIndex = 0
        var closestDistance = Double.infinity
        var closestProjectedDistance = 0.0

        for i in 0 ..< (self.geometry.count - 1) {
            let start = self.geometry[i]
            let end = self.geometry[i + 1]

            let (distance, projectedDistance) = self.distanceToLineSegment(
                point: point,
                start: start,
                end: end
            )

            if distance < closestDistance {
                closestDistance = distance
                closestIndex = i
                closestProjectedDistance = projectedDistance
            }
        }

        return RoutePosition(
            index: closestIndex,
            projectedDistance: closestProjectedDistance
        )
    }

    func calculateDistanceAlongRoute(
        from userLocation: CLLocationCoordinate2D,
        to featureLocation: CLLocationCoordinate2D
    ) -> CLLocationDistance {
        let userPosition = self.findPosition(for: userLocation)
        let featurePosition = self.findPosition(for: featureLocation)

        print("User position - index: \(userPosition.index), distance: \(userPosition.projectedDistance)")
        print("Feature position - index: \(featurePosition.index), distance: \(featurePosition.projectedDistance)")

        let directDistance = userLocation.distance(to: featureLocation)

        if directDistance <= LocationConstants.directDistanceThreshold {
            print("Within direct distance threshold, using direct distance: \(directDistance)m")
            return directDistance
        }

        if featurePosition.isBefore(userPosition) {
            print("Feature is behind user on route")
            return .infinity
        }

        var distance = -userPosition.projectedDistance

        for i in userPosition.index ..< featurePosition.index {
            guard i + 1 < self.geometry.count else { break }
            let segmentDistance = self.geometry[i].distance(to: self.geometry[i + 1])
            distance += segmentDistance
            print("Adding segment distance: \(segmentDistance)m")
        }

        if featurePosition.index < self.geometry.count {
            let finalSegment = self.geometry[featurePosition.index].distance(to: featureLocation)
            distance += finalSegment
            print("Adding final segment: \(finalSegment)m")
        }

        print("Final calculated distance: \(distance)m")
        return distance
    }

    private func distanceToLineSegment(
        point: CLLocationCoordinate2D,
        start: CLLocationCoordinate2D,
        end: CLLocationCoordinate2D
    ) -> (distance: CLLocationDistance, projectedDistance: CLLocationDistance) {
        let startToPoint = CLLocation(latitude: point.latitude, longitude: point.longitude)
            .distance(from: CLLocation(latitude: start.latitude, longitude: start.longitude))
        let startToEnd = CLLocation(latitude: start.latitude, longitude: start.longitude)
            .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude))

        if startToEnd == 0 {
            return (startToPoint, 0)
        }

        let t = max(0, min(1, dot(point, start, end) / (startToEnd * startToEnd)))
        let projectedPoint = self.interpolate(start: start, end: end, t: t)

        let distance = point.distance(to: projectedPoint)
        let projectedDistance = start.distance(to: projectedPoint)

        return (distance, projectedDistance)
    }

    private func dot(
        _ point: CLLocationCoordinate2D,
        _ start: CLLocationCoordinate2D,
        _ end: CLLocationCoordinate2D
    ) -> Double {
        let px = point.longitude - start.longitude
        let py = point.latitude - start.latitude
        let ex = end.longitude - start.longitude
        let ey = end.latitude - start.latitude
        return px * ex + py * ey
    }

    private func interpolate(
        start: CLLocationCoordinate2D,
        end: CLLocationCoordinate2D,
        t: Double
    ) -> CLLocationCoordinate2D {
        let lat = start.latitude + (end.latitude - start.latitude) * t
        let lon = start.longitude + (end.longitude - start.longitude) * t
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}
