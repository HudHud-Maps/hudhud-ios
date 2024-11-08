//
//  HorizonScanner.swift
//  HudHud
//
//  Created by Ali Hilal on 06/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation

// MARK: - LocationConstants

enum LocationConstants {
    static let closeProximityThreshold: CLLocationDistance = 50
    static let directDistanceThreshold: CLLocationDistance = 100
    static let defaultSpeedZoneAlertDistance: CLLocationDistance = 500
    static let significantDistanceChange: Double = 2
}

// MARK: - HorizonScanner

final class HorizonScanner {

    // MARK: Properties

    private var scanRange: Measurement<UnitLength>
    private var alertConfig: FeatureAlertConfig
    private var activeFeatures: [String: HorizonFeature] = [:]
    private var lastLocation: CLLocationCoordinate2D?
    private var routeGeometry: [CLLocationCoordinate2D] = []
    private let routerGeometryCalculator: EnhancedRouteGeometryCalculator = .init(geometry: [])

    // MARK: Lifecycle

    init(scanRange: Measurement<UnitLength>, alertConfig: FeatureAlertConfig) {
        self.alertConfig = alertConfig
        self.scanRange = scanRange
    }

    // MARK: Functions

    func updateRouteGeometry(_ geometry: [CLLocationCoordinate2D]) {
        self.routeGeometry = geometry
        self.routerGeometryCalculator.update(with: geometry)
    }

    func scan(
        features: [HorizonFeature],
        at location: CLLocationCoordinate2D,
        bearing: CLLocationDirection
    ) -> ScanResult {
        defer { lastLocation = location }

        var detectedFeatures: [HorizonFeature] = []
        var approachingFeatures: [FeatureDistance] = []
        var exitedFeatures: [HorizonFeature] = []

        for (id, feature) in self.activeFeatures {
            print("Processing feature \(id)")
            let userPosition = self.routerGeometryCalculator.findPosition(for: location)
            let featurePosition = self.routerGeometryCalculator.findPosition(for: feature.coordinate)
            let distance = self.calculateRouteDistance(from: location, to: feature.coordinate)

            if self.isFeaturePassed(
                feature,
                userPosition: userPosition,
                featurePosition: featurePosition,
                distance: distance
            ) {
                self.activeFeatures.removeValue(forKey: id)
                exitedFeatures.append(feature)
                continue
            }
            if distance > self.scanRange.converted(to: .meters).value {
                print("Feature \(id) is out of scan range")
                self.activeFeatures.removeValue(forKey: id)
                exitedFeatures.append(feature)
            }
        }

        for feature in features {
            print("Detect and process approaching feature \(feature.id)")
            let relevance = self.isFeatureRelevant(feature, userLocation: location, userBearing: bearing)

            guard case let .relevant(distance) = relevance else {
                print("Feature is not relevant \(feature.id)")
                continue
            }

            let measurement = Measurement<UnitLength>.meters(distance)
            print("The destinace until \(feature.id) is \(measurement.value) meters")

            let alertDistance = self.getAlertDistance(for: feature)
            print("The alert distance for \(feature.id) is \(alertDistance) meters")

            let withinAlertDistance = distance <= alertDistance
            print("Is feature within alert distance? \(withinAlertDistance)")

            if withinAlertDistance {
                if self.activeFeatures[feature.id] == nil {
                    self.activeFeatures[feature.id] = feature
                    detectedFeatures.append(feature)
                }
                let featureDistance = FeatureDistance(
                    feature: feature,
                    distance: measurement
                )
                approachingFeatures.append(featureDistance)
            }
        }

        return ScanResult(
            detectedFeatures: detectedFeatures,
            approachingFeatures: approachingFeatures,
            exitedFeatures: exitedFeatures
        )
    }

    private func isFeaturePassed(
        _: HorizonFeature,
        userPosition: RoutePosition,
        featurePosition: RoutePosition,
        distance: CLLocationDistance
    ) -> Bool {
        guard userPosition.isValid, featurePosition.isValid else { return false }
        return featurePosition.isBefore(userPosition) &&
            distance < LocationConstants.closeProximityThreshold
    }

    private func calculateRouteDistance(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) -> CLLocationDistance {
        if !self.routeGeometry.isEmpty {
            print("Calculating route distance using geometry with \(self.routeGeometry.count) points")
            let distance = self.routerGeometryCalculator.calculateDistanceAlongRoute(from: from, to: to)
            print("Route distance: \(distance)m")
            return distance
        }
        print("Calculating direct distance")
        let distance = from.distance(to: to)
        print("Direct distance: \(distance)m")
        return distance
    }

    private func getAlertDistance(for feature: HorizonFeature) -> CLLocationDistance {
        switch feature.type {
        case .speedCamera:
            return self.alertConfig.speedCameraConfig.initialAlertDistance.meters
        case .trafficIncident:
            return self.alertConfig.trafficIncidentConfig.initialAlertDistance.meters
        case .speedZone:
            return LocationConstants.defaultSpeedZoneAlertDistance
        }
    }

    private func isFeatureRelevant(
        _ feature: HorizonFeature,
        userLocation: CLLocationCoordinate2D,
        userBearing: CLLocationDirection
    ) -> FeatureRelevance {
        switch feature.type {
        case let .speedCamera(camera):
            let currentLocation = self.lastLocation ?? userLocation
            return self.isCameraRelevant(camera, userLocation: currentLocation, userCourse: userBearing)
        case .speedZone, .trafficIncident:
            let distance = self.calculateRouteDistance(from: userLocation, to: feature.coordinate)
            return .relevant(distance: distance)
        }
    }

    private func isCameraRelevant(
        _ camera: SpeedCamera,
        userLocation: CLLocationCoordinate2D,
        userCourse: CLLocationDirection
    ) -> FeatureRelevance {
        print("\nChecking camera relevance:")
        print("Camera ID: \(camera.id), Direction: \(camera.direction)")
        print("User course: \(userCourse)")
        let distance = self.calculateRouteDistance(from: userLocation, to: camera.location)
        switch camera.direction {
        case .forward:
            // for a forward facing camera:
            // if we are heading north (0dg) we should be south of the camera
            // if we are heading south (180dg) we should be north of the camera
//            let isGoingTowardsCamera = userLocation.latitude < camera.location.latitude &&
//                Direction.north.matches(userCourse) ||
//                userLocation.latitude > camera.location.latitude &&
//                Direction.south.matches(userCourse)

            let isGoingTowardsCamera = self.routerGeometryCalculator.isMovingTowardsFeature(
                userLocation: userLocation,
                featureLocation: camera.location,
                userCourse: userCourse
            )

            print("Forward camera - going towards camera: \(isGoingTowardsCamera)")
            return isGoingTowardsCamera ? .relevant(distance: distance) : .notRelevant

        case .backward:
            // for a backward-facing camera:
            // if we are heading north (0dg), we should be north of the camera
            // if we are heading south (180dg) we should be south of the camera
            let isMovingAwayFromCamera = !self.routerGeometryCalculator.isMovingTowardsFeature(
                userLocation: userLocation,
                featureLocation: camera.location,
                userCourse: userCourse
            )
            print("Backward camera - moving away from camera: \(isMovingAwayFromCamera)")
            return isMovingAwayFromCamera ? .relevant(distance: distance) : .notRelevant

        case .both:
            return .relevant(distance: distance)

        case let .specific(bearing):
            return Direction.from(degrees: bearing)?.matches(userCourse) == true ?
                .relevant(distance: distance) : .notRelevant
        }
    }
}

// MARK: - EnhancedRouteGeometryCalculator

final class EnhancedRouteGeometryCalculator {

    // MARK: Nested Types

    // MARK: - Types

    struct RouteSegment {
        let startIndex: Int
        let endIndex: Int
        let startPoint: CLLocationCoordinate2D
        let endPoint: CLLocationCoordinate2D
        let distance: CLLocationDistance
        let bearing: Double
    }

    struct RouteContext {
        let currentPosition: RoutePosition
        let upcomingSegments: [RouteSegment]
        let averageBearing: Double
    }

    // MARK: Properties

    private var geometry: [CLLocationCoordinate2D]
    private var cachedSegments: [RouteSegment] = []
    private var lastCalculatedDistance: CLLocationDistance?

    // MARK: Lifecycle

    // MARK: - Initialization

    init(geometry: [CLLocationCoordinate2D]) {
        self.geometry = geometry
        self.updateSegmentCache()
    }

    // MARK: Functions

    // MARK: - Public Methods

    func update(with geometry: [CLLocationCoordinate2D]) {
        self.geometry = geometry
        self.updateSegmentCache()
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

    func calculateDirectionContext(
        userLocation: CLLocationCoordinate2D,
        userCourse _: CLLocationDirection
    ) -> RouteContext {
        let position = self.findPosition(for: userLocation)
        let segments = self.getUpcomingSegments(from: position.index, count: 5)
        let avgBearing = self.calculateAverageBearing(segments: segments)

        return RouteContext(
            currentPosition: position,
            upcomingSegments: segments,
            averageBearing: avgBearing
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

        if userPosition.index == featurePosition.index {
//            let segment = cachedSegments[userPosition.index]
            let distance = abs(featurePosition.projectedDistance - userPosition.projectedDistance)
            let directDistance = userLocation.distance(to: featureLocation)
            if abs(distance - directDistance) > 10 {
                return directDistance
            }
            return distance
        }

        if featurePosition.isBefore(userPosition) {
            print("Feature is behind user on route")
            return .infinity
        }

        var distance = -userPosition.projectedDistance

        for i in userPosition.index ..< featurePosition.index {
            guard i < self.cachedSegments.count else { break }
            distance += self.cachedSegments[i].distance
        }

        if featurePosition.index < self.geometry.count {
            distance += featurePosition.projectedDistance
        }

        // smoothing to prevent jumps
        if let lastDistance = lastCalculatedDistance {
            let change = abs(distance - lastDistance)
            if change > 10 {
                distance = lastDistance + (distance > lastDistance ? 10 : -10)
            }
        }

        self.lastCalculatedDistance = distance
        return distance
    }

    func isMovingTowardsFeature(
        userLocation: CLLocationCoordinate2D,
        featureLocation: CLLocationCoordinate2D,
        userCourse: CLLocationDirection
    ) -> Bool {
        let context = self.calculateDirectionContext(
            userLocation: userLocation,
            userCourse: userCourse
        )

        if self.isNorthSouthRoad(segments: context.upcomingSegments) {
            let isHeadingNorth = Direction.north.matches(userCourse)
            let isFeatureNorth = featureLocation.latitude > userLocation.latitude

            let isHeadingSouth = Direction.south.matches(userCourse)
            let isFeatureSouth = featureLocation.latitude < userLocation.latitude

            return (isHeadingNorth && isFeatureNorth) ||
                (isHeadingSouth && isFeatureSouth)
        }

        let featureBearing = userLocation.bearing(to: featureLocation)
        let bearingDiff = abs(context.averageBearing - featureBearing)

        return bearingDiff <= 45.0 || context.upcomingSegments.contains { segment in
            let segmentToFeatureBearing = segment.endPoint.bearing(to: featureLocation)
            return abs(segment.bearing - segmentToFeatureBearing) <= 45.0
        }
    }

    private func isNorthSouthRoad(segments: [RouteSegment]) -> Bool {
        guard !segments.isEmpty else { return false }
        return segments.contains { segment in
            let bearing = segment.bearing
            return (0 ... 20).contains(bearing) ||
                (160 ... 200).contains(bearing)
        }
    }

    // MARK: - Private Methods

    private func updateSegmentCache() {
        guard !self.geometry.isEmpty else {
            return
        }
        self.cachedSegments = []
        for i in 0 ..< (self.geometry.count - 1) {
            let start = self.geometry[i]
            let end = self.geometry[i + 1]
            let segment = RouteSegment(
                startIndex: i,
                endIndex: i + 1,
                startPoint: start,
                endPoint: end,
                distance: start.distance(to: end),
                bearing: start.bearing(to: end)
            )
            self.cachedSegments.append(segment)
        }
    }

    private func getUpcomingSegments(from index: Int, count: Int) -> [RouteSegment] {
        guard index < self.cachedSegments.count else { return [] }
        let endIndex = min(index + count, self.cachedSegments.count)
        return Array(self.cachedSegments[index ..< endIndex])
    }

    private func calculateAverageBearing(segments: [RouteSegment]) -> Double {
        guard !segments.isEmpty else { return 0 }
        let totalBearing = segments.reduce(0.0) { $0 + $1.bearing }
        return totalBearing / Double(segments.count)
    }

    private func calculateContextAwareDistance(
        from userPosition: RoutePosition,
        to featurePosition: RoutePosition,
        userLocation: CLLocationCoordinate2D,
        featureLocation: CLLocationCoordinate2D
    ) -> CLLocationDistance {
        let isUTurn = self.isUTurnBetween(
            startIndex: userPosition.index,
            endIndex: featurePosition.index
        )

        if isUTurn {
            return self.calculateUTurnDistance(
                from: userPosition,
                to: featurePosition,
                userLocation: userLocation,
                featureLocation: featureLocation
            )
        }

        var distance = -userPosition.projectedDistance

        for i in userPosition.index ..< featurePosition.index {
            guard i < self.cachedSegments.count else { break }
            distance += self.cachedSegments[i].distance
        }

        if featurePosition.index < self.geometry.count {
            distance += featurePosition.projectedDistance
        }

        return distance
    }

    private func isUTurnBetween(startIndex: Int, endIndex: Int) -> Bool {
        guard startIndex < endIndex,
              startIndex + 2 < self.cachedSegments.count,
              endIndex - 2 >= 0 else { return false }

        let startBearing = self.cachedSegments[startIndex].bearing
        let endBearing = self.cachedSegments[endIndex - 1].bearing

        let bearingDiff = abs(startBearing - endBearing)
        return bearingDiff > 150 && bearingDiff < 210 // approximately 180° ± 30°
    }

    private func calculateUTurnDistance(
        from userPosition: RoutePosition,
        to featurePosition: RoutePosition,
        userLocation _: CLLocationCoordinate2D,
        featureLocation _: CLLocationCoordinate2D
    ) -> CLLocationDistance {
        let uTurnIndex = self.findUTurnVertex(
            from: userPosition.index,
            to: featurePosition.index
        )

        var distance: CLLocationDistance = 0

        for i in userPosition.index ..< uTurnIndex {
            guard i < self.cachedSegments.count else { break }
            distance += self.cachedSegments[i].distance
        }

        for i in uTurnIndex ..< featurePosition.index {
            guard i < self.cachedSegments.count else { break }
            distance += self.cachedSegments[i].distance
        }

        if featurePosition.index < self.geometry.count {
            distance += featurePosition.projectedDistance
        }

        return distance
    }

    private func findUTurnVertex(from startIndex: Int, to endIndex: Int) -> Int {
        var maxBearingChange = 0.0
        var uTurnIndex = startIndex

        for i in startIndex ..< endIndex where i + 1 < self.cachedSegments.count {
            let bearingChange = abs(cachedSegments[i].bearing - cachedSegments[i + 1].bearing)
            if bearingChange > maxBearingChange {
                maxBearingChange = bearingChange
                uTurnIndex = i
            }
        }

        return uTurnIndex
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
