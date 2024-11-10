//
//  HorizonEngine.swift
//  HudHud
//
//  Created by Ali Hilal on 04/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Combine
import CoreLocation
import FerrostarCoreFFI
import Foundation

// MARK: - ActiveFeatureState

private struct ActiveFeatureState {
    let feature: HorizonFeature
    let firstDetectedAt: Date
    var lastDistance: Measurement<UnitLength>
    var hasAlerted: Bool
}

// MARK: - HorizonEngine

@Observable
final class HorizonEngine {

    // MARK: Properties

    let alertConfig: FeatureAlertConfig

    private let scanner: HorizonScanner
    private let eventsSubject = PassthroughSubject<HorizionEvent, Never>()
    private var cancellables = Set<AnyCancellable>()

    private var routeFeatures: [HorizonFeature] = []
    private var activeFeatures: [String: ActiveFeatureState] = [:]
    private let processingQueue = DispatchQueue(label: "com.hudhud.horizonEngine", qos: .userInitiated)

    // MARK: Computed Properties

    var events: AnyPublisher<HorizionEvent, Never> {
        self.eventsSubject.eraseToAnyPublisher()
    }

    // MARK: Lifecycle

    init(configuration: NavigationConfig) {
        self.alertConfig = configuration.featureAlertConfig
        self.scanner = HorizonScanner(scanRange: configuration.horizonScanRange, alertConfig: configuration.featureAlertConfig)
    }

    // MARK: Functions

    func startMonitoring(route: Route) {
        self.routeFeatures = RouteFeatureExtractor.extractFeatures(from: route)
        self.scanner.updateRouteGeometry(route.geometry.clLocationCoordinate2Ds)
    }

    func stopMonitoring() {
        self.routeFeatures.removeAll()
        self.activeFeatures.removeAll()
        self.scanner.updateRouteGeometry([])
    }

    func processLocation(_ location: CLLocation) {
        self.processingQueue.async { [weak self] in
            guard let self else { return }

            NavigationLogger.beginFrame("Location Update: (\(location.coordinate.latitude), \(location.coordinate.longitude))")
            defer { NavigationLogger.endFrame() }

            NavigationLogger.log("Bearing: \(location.course)°")

            let scanResult = self.scanner.scan(
                features: self.routeFeatures,
                at: location.coordinate,
                bearing: location.course
            )

            self.processFeatures(scanResult, at: location)
        }
    }

    private func processFeatures(_ result: ScanResult, at _: CLLocation) {
        NavigationLogger.beginScope("Process Features")
        defer { NavigationLogger.endScope() }
        NavigationLogger.beginScope("New Detections")

        for feature in result.detectedFeatures {
            NavigationLogger.log("Detected: \(feature.id) (\(feature.type))")
            if self.activeFeatures[feature.id] == nil {
                let state = ActiveFeatureState(
                    feature: feature,
                    firstDetectedAt: Date(),
                    lastDistance: .init(value: 0, unit: .meters),
                    hasAlerted: false
                )
                self.activeFeatures[feature.id] = state
            }
            NavigationLogger.endScope()
        }

        // approaching features
        if !result.approachingFeatures.isEmpty {
            NavigationLogger.beginScope("Approaching Features")
            for featureDistance in result.approachingFeatures {
                NavigationLogger.beginScope("Feature: \(featureDistance.feature.id)")

                guard var state = activeFeatures[featureDistance.feature.id] else {
                    NavigationLogger.log("State not found", level: .error)
                    NavigationLogger.endScope()
                    continue
                }

                let distanceChange = abs(state.lastDistance.value - featureDistance.distance.value)
                let significantChange = self.isDistanceChangeSignificant(state.lastDistance, featureDistance.distance)

                NavigationLogger.log("Previous Distance: \(state.lastDistance.value)m")
                NavigationLogger.log("Current Distance: \(featureDistance.distance.value)m")
                NavigationLogger.log("Change: \(distanceChange)m")
                NavigationLogger.log("Significant: \(significantChange)")
                NavigationLogger.log("Previously Alerted: \(state.hasAlerted)")

                switch featureDistance.feature.type {
                case let .speedCamera(camera):
                    NavigationLogger.beginScope("Speed Camera Processing")
                    if !state.hasAlerted {
                        NavigationLogger.log("Sending initial alert")
                        self.eventsSubject.send(.approachingSpeedCamera(camera, distance: featureDistance.distance))
                        state.hasAlerted = true
                    } else if significantChange {
                        NavigationLogger.log("Sending distance update")
                        self.eventsSubject.send(.approachingSpeedCamera(camera, distance: featureDistance.distance))
                    } else {
                        NavigationLogger.log("No update needed")
                    }
                    NavigationLogger.endScope()

                case let .trafficIncident(incident):
                    NavigationLogger.beginScope("Traffic Incident Processing")
                    if !state.hasAlerted || significantChange {
                        NavigationLogger.log("Sending alert/update")
                        self.eventsSubject.send(.approachingTrafficIncident(incident, distance: featureDistance.distance))
                        state.hasAlerted = true
                    }
                    NavigationLogger.endScope()

                case let .speedZone(zone):
                    NavigationLogger.beginScope("Speed Zone Processing")
                    if !state.hasAlerted {
                        NavigationLogger.log("Sending entry alert")
                        self.eventsSubject.send(.enteredSpeedZone(limit: zone.limit))
                        state.hasAlerted = true
                    }
                    NavigationLogger.endScope()
                }

                state.lastDistance = featureDistance.distance
                self.activeFeatures[featureDistance.feature.id] = state
                NavigationLogger.endScope()
            }
            NavigationLogger.endScope()
        }

        // exited features
        if !result.exitedFeatures.isEmpty {
            NavigationLogger.beginScope("Exited Features")
            for feature in result.exitedFeatures {
                NavigationLogger.log("Feature \(feature.id) exited")
                self.activeFeatures.removeValue(forKey: feature.id)

                switch feature.type {
                case let .speedCamera(camera):
                    NavigationLogger.log("Sending speed camera passed event")
                    self.eventsSubject.send(.passedSpeedCamera(camera))
                case let .trafficIncident(incident):
                    NavigationLogger.log("Sending incident passed event")
                    self.eventsSubject.send(.passedTrafficIncident(incident))
                case .speedZone:
                    NavigationLogger.log("Sending speed zone exit event")
                    self.eventsSubject.send(.exitedSpeedZone)
                }
            }
            NavigationLogger.endScope()
        }
    }

    private func isDistanceChangeSignificant(
        _ oldDistance: Measurement<UnitLength>,
        _ newDistance: Measurement<UnitLength>
    ) -> Bool {
        let change = abs(oldDistance.value - newDistance.value)
        let roundedChange = round(change * 10) / 10
        return roundedChange >= LocationConstants.significantDistanceChange
    }
}

// MARK: - RouteFeatureExtractor

enum RouteFeatureExtractor {
    static func extractFeatures(from route: Route) -> [HorizonFeature] {
        var features: [HorizonFeature] = []

        let incidentFeatures = route.incidents.map { incident in
            HorizonFeature(
                id: incident.id,
                type: .trafficIncident(incident),
                coordinate: incident.location
            )
        }

        let cameraFeatures = route.speedCameras.map { camera in
            HorizonFeature(
                id: camera.id,
                type: .speedCamera(camera),
                coordinate: camera.location
            )
        }

        features.append(contentsOf: incidentFeatures)
        features.append(contentsOf: cameraFeatures)

        return features
    }
}

import CoreLocation
import FerrostarCore
import FerrostarCoreFFI

// MARK: - MockFeaturePlacer

struct MockFeaturePlacer {

    // MARK: Nested Types

    struct PlacedFeatures {
        let camera: SpeedCamera?
        let incident: TrafficIncident?
    }

    // MARK: Properties

    let geometry: [CLLocationCoordinate2D]
    let routeLength: Double

    private let minCameraDistance = 1100.0
    private let maxCameraDistance = 1500.0
    private let incidentCameraSpacing = 1500.0

    // MARK: Functions

    func placeFeatures() -> PlacedFeatures {
        let cameraDistance = (minCameraDistance + self.maxCameraDistance) / 2
        guard let (cameraLocation, cameraLocationIndex) = findLocationAtDistance(cameraDistance) else {
            return PlacedFeatures(camera: nil, incident: nil)
        }

        let camera = SpeedCamera(
            id: "test-camera",
            speedLimit: .kilometersPerHour(120),
            type: .fixed,
            direction: .forward,
            captureRange: .kilometers(2),
            location: cameraLocation
        )

        let incidentDistance = cameraDistance + self.incidentCameraSpacing
        guard self.routeLength >= incidentDistance,
              let (incidentLocation, _) = findLocationAtDistance(incidentDistance, lastDistance: cameraDistance, lastIndex: cameraLocationIndex) else {
            return PlacedFeatures(camera: camera, incident: nil)
        }

        let incident = TrafficIncident(
            id: "test-incident",
            type: .accident,
            severity: .moderate,
            location: incidentLocation,
            description: "",
            startTime: Date(),
            endTime: nil,
            length: .kilometers(1.5),
            delayInSeconds: 600
        )

        return PlacedFeatures(camera: camera, incident: incident)
    }

    private func findLocationAtDistance(_ targetDistance: Double, lastDistance: Double? = nil, lastIndex: Int = 0) -> (CLLocationCoordinate2D, Int)? {
        var coveredDistance = 0.0
        var startIndex = 0

        guard targetDistance <= self.routeLength, targetDistance > 0 else { return nil }

        if let lastDistance {
            coveredDistance = lastDistance
            startIndex = lastIndex
        }

        for i in startIndex ..< (self.geometry.count - 1) {
            let currentPoint = self.geometry[i]
            let nextPoint = self.geometry[i + 1]

            let current = CLLocation(latitude: currentPoint.latitude, longitude: currentPoint.longitude)
            let next = CLLocation(latitude: nextPoint.latitude, longitude: nextPoint.longitude)

            let segmentLength = current.distance(from: next)

            if targetDistance <= coveredDistance + segmentLength {
                let segmentProgress = (targetDistance - coveredDistance) / segmentLength

                let lat = currentPoint.latitude + (nextPoint.latitude - currentPoint.latitude) * segmentProgress
                let lon = currentPoint.longitude + (nextPoint.longitude - currentPoint.longitude) * segmentProgress

                return (CLLocationCoordinate2D(latitude: lat, longitude: lon), i)
            }

            coveredDistance += segmentLength
        }

        return nil
    }
}

extension Route {
    static var mockIncidents: [TrafficIncident] = []
    static var mockSpeedCameras: [SpeedCamera] = []

    private static var _placedFeatures: MockFeaturePlacer.PlacedFeatures?

    private var placedFeatures: MockFeaturePlacer.PlacedFeatures {
        if let existing = Self._placedFeatures {
            return existing
        }
        let placer = MockFeaturePlacer(geometry: geometry.clLocationCoordinate2Ds, routeLength: self.distance)
        let features = placer.placeFeatures()
        Self._placedFeatures = features
        return features
    }

    var incidents: [TrafficIncident] {
        if !Self.mockIncidents.isEmpty { return Self.mockIncidents }
        return self.placedFeatures.incident.map { [$0] } ?? []
    }

    var speedCameras: [SpeedCamera] {
        if !Self.mockSpeedCameras.isEmpty { return Self.mockSpeedCameras }
        return self.placedFeatures.camera.map { [$0] } ?? []
    }
}
