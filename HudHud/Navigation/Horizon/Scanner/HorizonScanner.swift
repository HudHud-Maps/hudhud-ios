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
    static let closeProximityThreshold: CLLocationDistance = 5
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
    private let routerGeometryCalculator = RouteGeometryCalculator(geometry: [])

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

    func scan(features: [HorizonFeature],
              at location: CLLocationCoordinate2D,
              bearing: CLLocationDirection) -> ScanResult {
        defer { lastLocation = location }

        NavigationLogger.beginFrame("Horizon Scan at (\(location.latitude), \(location.longitude))")
        NavigationLogger.log("Bearing: \(bearing)°")

        var detectedFeatures: [HorizonFeature] = []
        var approachingFeatures: [FeatureDistance] = []
        var exitedFeatures: [HorizonFeature] = []

        for (id, feature) in self.activeFeatures {
            NavigationLogger.beginScope("Feature: \(id)")

            let userPosition = self.routerGeometryCalculator.findPosition(for: location)
            let featurePosition = self.routerGeometryCalculator.findPosition(for: feature.coordinate)
            let distance = self.calculateRouteDistance(from: location, to: feature.coordinate, featureId: feature.id)

            NavigationLogger.log("User Position - index: \(userPosition.index), distance: \(userPosition.projectedDistance)")
            NavigationLogger.log("Feature Position - index: \(featurePosition.index), distance: \(featurePosition.projectedDistance)")
            NavigationLogger.log("Route Distance: \(distance)m")

            if self.isFeaturePassed(feature,
                                    userPosition: userPosition,
                                    featurePosition: featurePosition,
                                    distance: distance) {
                NavigationLogger.log("Feature passed", level: .debug)
                self.activeFeatures.removeValue(forKey: id)
                exitedFeatures.append(feature)
                continue
            }
            if distance > self.scanRange.converted(to: .meters).value {
                NavigationLogger.log("Feature \(id) is out of scan range")
                self.activeFeatures.removeValue(forKey: id)
                exitedFeatures.append(feature)
            }
            NavigationLogger.endScope()
        }
        NavigationLogger.endScope()

        NavigationLogger.beginScope("Processing New Features")
        for feature in features {
            NavigationLogger.beginScope("Feature: \(feature.id)")
            NavigationLogger.log("Type: \(feature.type)")

            let relevance = self.isFeatureRelevant(feature, userLocation: location, userBearing: bearing)

            guard case let .relevant(distance) = relevance else {
                NavigationLogger.log("Feature not relevant", level: .debug)
                NavigationLogger.endScope()
                continue
            }

            let measurement = Measurement<UnitLength>.meters(distance)
            NavigationLogger.log("Distance: \(measurement.value)m")

            let alertDistance = self.getAlertDistance(for: feature)
            NavigationLogger.log("Alert Distance: \(alertDistance)m")

            let withinAlertDistance = distance <= alertDistance
            NavigationLogger.log("Within Alert Distance: \(withinAlertDistance)")

            if withinAlertDistance {
                if self.activeFeatures[feature.id] == nil {
                    NavigationLogger.log("New feature became active and entered alert distance", level: .info)
                    self.activeFeatures[feature.id] = feature
                    detectedFeatures.append(feature)
                }
                let featureDistance = FeatureDistance(feature: feature,
                                                      distance: measurement)
                approachingFeatures.append(featureDistance)
                NavigationLogger.log("Added to approaching features")
            }
            NavigationLogger.endScope()
        }
        NavigationLogger.endScope()

        return ScanResult(detectedFeatures: detectedFeatures,
                          approachingFeatures: approachingFeatures,
                          exitedFeatures: exitedFeatures)
    }
}

private extension HorizonScanner {
    func isFeaturePassed(_: HorizonFeature,
                         userPosition: RoutePosition,
                         featurePosition: RoutePosition,
                         distance: CLLocationDistance) -> Bool {
        guard userPosition.isValid, featurePosition.isValid else { return false }
        return featurePosition.isBefore(userPosition) &&
            distance < LocationConstants.closeProximityThreshold
    }

    func calculateRouteDistance(from: CLLocationCoordinate2D,
                                to: CLLocationCoordinate2D,
                                featureId: String) -> CLLocationDistance {
        NavigationLogger.beginScope("Calculate Route Distance")
        defer { NavigationLogger.endScope() }

        NavigationLogger.log("From: (\(from.latitude), \(from.longitude))")
        NavigationLogger.log("To: (\(to.latitude), \(to.longitude))")

        if !self.routeGeometry.isEmpty {
            NavigationLogger.log("Using route geometry with \(self.routeGeometry.count) points")
            let distance = self.routerGeometryCalculator.calculateDistanceAlongRoute(from: from, to: to, featureId: featureId)
            NavigationLogger.log("Route distance: \(distance)m", level: .debug)
            return distance
        }

        NavigationLogger.log("Using direct distance calculation")
        let distance = from.distance(to: to)
        NavigationLogger.log("Direct distance: \(distance)m", level: .debug)
        return distance
    }

    func getAlertDistance(for feature: HorizonFeature) -> CLLocationDistance {
        switch feature.type {
        case .speedCamera:
            return self.alertConfig.speedCameraConfig.initialAlertDistance.meters
        case .trafficIncident:
            return self.alertConfig.trafficIncidentConfig.initialAlertDistance.meters
        case .speedZone:
            return LocationConstants.defaultSpeedZoneAlertDistance
        }
    }

    func isFeatureRelevant(_ feature: HorizonFeature,
                           userLocation: CLLocationCoordinate2D,
                           userBearing: CLLocationDirection) -> FeatureRelevance {
        switch feature.type {
        case let .speedCamera(camera):
            let currentLocation = self.lastLocation ?? userLocation
            let distance = self.calculateRouteDistance(from: currentLocation, to: camera.location, featureId: camera.id)
            return self.isCameraRelevant(camera, userLocation: currentLocation, userCourse: userBearing, distance: distance)
        case let .speedZone(feature):
            let distance = self.calculateRouteDistance(from: userLocation, to: feature.location, featureId: feature.id.uuidString)
            return .relevant(distance: distance)
        case let .trafficIncident(feature):
            let distance = self.calculateRouteDistance(from: userLocation, to: feature.location, featureId: feature.id)
            return .relevant(distance: distance)
        }
    }

    func isCameraRelevant(_ camera: SpeedCamera,
                          userLocation: CLLocationCoordinate2D,
                          userCourse: CLLocationDirection,
                          distance: CLLocationDistance) -> FeatureRelevance {
        NavigationLogger.beginScope("Camera Relevance Check")
        defer { NavigationLogger.endScope() }

        NavigationLogger.log("Camera ID: \(camera.id)")
        NavigationLogger.log("Camera Direction: \(camera.direction)")
        NavigationLogger.log("User Course: \(userCourse)°")
        NavigationLogger.log("User Location: (\(userLocation.latitude), \(userLocation.longitude))")
        NavigationLogger.log("Camera Location: (\(camera.location.latitude), \(camera.location.longitude))")

        switch camera.direction {
        case .forward:
            NavigationLogger.beginScope("Forward Camera Check")
            let isGoingTowardsCamera = self.routerGeometryCalculator.isMovingTowardsFeature(userLocation: userLocation,
                                                                                            featureLocation: camera.location,
                                                                                            userCourse: userCourse)
            NavigationLogger.log("Going Towards Camera: \(isGoingTowardsCamera)")
            NavigationLogger.endScope()
            return isGoingTowardsCamera ? .relevant(distance: distance) : .notRelevant

        case .backward:
            NavigationLogger.beginScope("Backward Camera Check")
            let isMovingAwayFromCamera = !self.routerGeometryCalculator.isMovingTowardsFeature(userLocation: userLocation,
                                                                                               featureLocation: camera.location,
                                                                                               userCourse: userCourse)
            NavigationLogger.log("Moving Away From Camera: \(isMovingAwayFromCamera)")
            NavigationLogger.endScope()
            return isMovingAwayFromCamera ? .relevant(distance: distance) : .notRelevant

        case .both:
            NavigationLogger.log("Bidirectional Camera - Always Relevant")
            return .relevant(distance: distance)

        case let .specific(bearing):
            NavigationLogger.beginScope("Specific Direction Check")
            let isMatching = Direction.from(degrees: bearing)?.matches(userCourse) == true
            NavigationLogger.log("Required Bearing: \(bearing)°")
            NavigationLogger.log("Direction Matches: \(isMatching)")
            NavigationLogger.endScope()
            return isMatching ? .relevant(distance: distance) : .notRelevant
        }
    }
}
