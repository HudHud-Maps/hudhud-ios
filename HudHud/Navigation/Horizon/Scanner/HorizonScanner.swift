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
    static let directDistanceThreshold: CLLocationDistance = 1000
    static let defaultSpeedZoneAlertDistance: CLLocationDistance = 500
    static let significantDistanceChange: Double = 10
}

// MARK: - HorizonScanner

final class HorizonScanner {

    // MARK: Properties

    private var scanRange: Measurement<UnitLength>
    private var alertConfig: FeatureAlertConfig
    private var activeFeatures: [String: HorizonFeature] = [:]
    private var lastLocation: CLLocationCoordinate2D?
    private var routeGeometry: [CLLocationCoordinate2D] = []
    private let routerGeometryCalculator: RouteGeometryCalculator = .init(geometry: [])

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
            let isGoingTowardsCamera = userLocation.latitude < camera.location.latitude &&
                Direction.north.matches(userCourse) ||
                userLocation.latitude > camera.location.latitude &&
                Direction.south.matches(userCourse)

            print("Forward camera - going towards camera: \(isGoingTowardsCamera)")
            return isGoingTowardsCamera ? .relevant(distance: distance) : .notRelevant

        case .backward:
            // for a backward-facing camera:
            // if we are heading north (0dg), we should be north of the camera
            // if we are heading south (180dg) we should be south of the camera
            let isGoingAwayFromCamera = userLocation.latitude > camera.location.latitude &&
                Direction.north.matches(userCourse) ||
                userLocation.latitude < camera.location.latitude &&
                Direction.south.matches(userCourse)
            print("Backward camera - going away from camera: \(isGoingAwayFromCamera)")
            return isGoingAwayFromCamera ? .relevant(distance: distance) : .notRelevant

        case .both:
            return .relevant(distance: distance)

        case let .specific(bearing):
            return Direction.from(degrees: bearing)?.matches(userCourse) == true ?
                .relevant(distance: distance) : .notRelevant
        }
    }
}
