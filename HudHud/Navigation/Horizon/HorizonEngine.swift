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

            let scanResult = self.scanner.scan(
                features: self.routeFeatures,
                at: location.coordinate,
                bearing: location.course
            )

            self.processFeatures(scanResult, at: location)
        }
    }

    private func processFeatures(_ result: ScanResult, at location: CLLocation) {
        print("\nProcessing features at location: \(location.coordinate)")

        for feature in result.detectedFeatures {
            let state = ActiveFeatureState(
                feature: feature,
                firstDetectedAt: Date(),
                lastDistance: .init(value: 0, unit: .meters),
                hasAlerted: false
            )
            self.activeFeatures[feature.id] = state
        }

        for featureDistance in result.approachingFeatures {
            guard var state = activeFeatures[featureDistance.feature.id] else { continue }

            let distanceChange = abs(state.lastDistance.value - featureDistance.distance.value)
            let significantChange = self.isDistanceChangeSignificant(state.lastDistance, featureDistance.distance)
            print("Distance change for feature \(featureDistance.feature.id): \(distanceChange)m")
            print("Is change significant? \(significantChange)")

            switch featureDistance.feature.type {
            case let .speedCamera(camera):
                print("Processing speed camera: \(camera.id)")
                print("Previous distance: \(state.lastDistance.value)m")
                print("Current distance: \(featureDistance.distance.value)m")
                print("Distance change: \(distanceChange)m")
                print("Has alerted before? \(state.hasAlerted)")

                if !state.hasAlerted {
                    print("Sending initial alert")
                    self.eventsSubject.send(.approachingSpeedCamera(camera, distance: featureDistance.distance))
                    state.hasAlerted = true
                } else if significantChange {
                    print("Sending distance update")
                    self.eventsSubject.send(.approachingSpeedCamera(camera, distance: featureDistance.distance))
                } else {
                    print("Change not significant enough for update")
                }

            case let .trafficIncident(incident):
                if !state.hasAlerted {
                    self.eventsSubject.send(.approachingTrafficIncident(incident, distance: featureDistance.distance))
                    state.hasAlerted = true
                } else if significantChange {
                    self.eventsSubject.send(.approachingTrafficIncident(incident, distance: featureDistance.distance))
                }

            case let .speedZone(zone):
                // speed zones dont need distance updates just entry/exit events
                if !state.hasAlerted {
                    self.eventsSubject.send(.enteredSpeedZone(limit: zone.limit))
                    state.hasAlerted = true
                }
            }

            state.hasAlerted = true
            state.lastDistance = featureDistance.distance
            self.activeFeatures[featureDistance.feature.id] = state
        }

        for feature in result.exitedFeatures {
            self.activeFeatures.removeValue(forKey: feature.id)

            switch feature.type {
            case let .speedCamera(camera):
                self.eventsSubject.send(.passedSpeedCamera(camera))
            case let .trafficIncident(incident):
                self.eventsSubject.send(.passedTrafficIncident(incident))
            case .speedZone:
                self.eventsSubject.send(.exitedSpeedZone)
            }
        }
    }

    private func isDistanceChangeSignificant(
        _ oldDistance: Measurement<UnitLength>,
        _ newDistance: Measurement<UnitLength>
    ) -> Bool {
        let change = abs(oldDistance.value - newDistance.value)
        let roundedChange = round(change * 10) / 10
        return roundedChange >= 10
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

extension Route {
    static var mockIncidents: [TrafficIncident] = []
    static var mockSpeedCameras: [SpeedCamera] = []

    var incidents: [TrafficIncident] {
        Self.mockIncidents
    }

    var speedCameras: [SpeedCamera] {
        Self.mockSpeedCameras
    }
}

// MARK: - FeatureTracker

private struct FeatureTracker {

    // MARK: Properties

    var activeFeatures: [String: ActiveFeatureState]

    // MARK: Functions

    mutating func trackFeature(_ feature: HorizonFeature) -> Bool {
        guard self.activeFeatures[feature.id] == nil else { return false }
        self.activeFeatures[feature.id] = ActiveFeatureState(
            feature: feature,
            firstDetectedAt: Date(),
            lastDistance: .meters(0),
            hasAlerted: false
        )
        return true
    }

    mutating func removeFeature(_ feature: HorizonFeature) {
        self.activeFeatures.removeValue(forKey: feature.id)
    }
}
