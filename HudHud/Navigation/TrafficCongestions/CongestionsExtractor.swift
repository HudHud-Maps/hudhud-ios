//
//  CongestionsExtractor.swift
//  HudHud
//
//  Created by Ali Hilal on 17/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import FerrostarCore
import FerrostarCoreFFI

// MARK: - CongestionSegment

extension Route {
    var annotations: [ValhallaOsrmAnnotation] {
        let decoder = JSONDecoder()

        return steps
            .compactMap(\.annotations)
            .flatMap { annotations in
                annotations.compactMap { annotationString in
                    guard let data = annotationString.data(using: .utf8) else {
                        return nil
                    }
                    return try? decoder.decode(ValhallaOsrmAnnotation.self, from: data)
                }
            }
    }
}

extension Route {

    func extractCongestionSegments() -> [CongestionSegment] {
        var mergedSegments: [CongestionSegment] = []
        var currentSegment: CongestionSegment?
        var currentIndex = 0

        for annotation in self.annotations {
            guard let congestion = annotation.congestion else {
                continue
            }

            let startIndex = currentIndex
            let endIndex = startIndex + 1

            if endIndex >= geometry.count {
                break
            }

            let segmentGeometry = Array(geometry[startIndex ... endIndex])

            if let current = currentSegment,
               current.level == congestion,
               let lastSegment = current.geometry.last {
                currentSegment = CongestionSegment(
                    level: congestion,
                    geometry: current.geometry + [lastSegment]
                )
            } else {
                if let current = currentSegment {
                    mergedSegments.append(current)
                }
                currentSegment = CongestionSegment(
                    level: congestion,
                    geometry: segmentGeometry.map(\.clLocationCoordinate2D)
                )
            }

            currentIndex = endIndex
        }

        if let lastSegment = currentSegment {
            mergedSegments.append(lastSegment)
        }
        return mergedSegments
    }

    private func findEndIndex(startingFrom startIndex: Int, distance: Double) -> Int {
        var remainingDistance = distance
        var currentIndex = startIndex

        while currentIndex < geometry.count - 1, remainingDistance > 0 {
            let segmentDistance = geometry[currentIndex]
                .clLocationCoordinate2D
                .distance(to: geometry[currentIndex + 1].clLocationCoordinate2D)
            if remainingDistance >= segmentDistance {
                remainingDistance -= segmentDistance
                currentIndex += 1
            } else {
                break
            }
        }

        return currentIndex
    }
}

import Combine
import CoreLocation
import FerrostarCore
import FerrostarCoreFFI
import MapLibre

public typealias UserLocation = FerrostarCoreFFI.UserLocation

// MARK: - LocationManagerProxy

public class LocationManagerProxy: NSObject, MLNLocationManager, ObservableObject {

    // MARK: Properties

    public weak var delegate: (any MLNLocationManagerDelegate)?

    public var headingOrientation: CLDeviceOrientation = .portrait

    private let locationProvider: LocationProviding
    private var cancellable: AnyCancellable?

    private var _lastLocation: CLLocationCoordinate2D?

    // MARK: Computed Properties

    public var lastLocation: CLLocationCoordinate2D? {
        self._lastLocation
    }

    public var lastCLHeading: CLHeading? {
        guard let heading = locationProvider.lastHeading else { return nil }
        let clHeading = CLHeading()
        clHeading.setValue(Double(heading.trueHeading), forKey: "trueHeading")
        clHeading.setValue(Double(heading.accuracy), forKey: "headingAccuracy")
        clHeading.setValue(heading.timestamp, forKey: "timestamp")
        return clHeading
    }

    public var authorizationStatus: CLAuthorizationStatus {
        self.locationProvider.authorizationStatus
    }

    // MARK: Lifecycle

    public init(locationProvider: LocationProviding) {
        self.locationProvider = locationProvider
        super.init()
//        setupLocationUpdates()
    }

    // MARK: Functions

    public func requestAlwaysAuthorization() {
        // No-op, handled by LocationProviding implementation
    }

    public func requestWhenInUseAuthorization() {
        // No-op, handled by LocationProviding implementation
    }

    public func dismissHeadingCalibrationDisplay() {
        // No-op
    }

    public func startUpdatingLocation() {
        self.locationProvider.startUpdating()
    }

    public func stopUpdatingLocation() {
        self.locationProvider.stopUpdating()
    }

    public func startUpdatingHeading() {
        // Handled by startUpdating() in LocationProviding
    }

    public func stopUpdatingHeading() {
        // Handled by stopUpdating() in LocationProviding
    }

    func updateLocation(_ location: CLLocation) {
        self._lastLocation = location.coordinate
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.delegate?.locationManager(self, didUpdate: [location])
        }
    }

    private func setupLocationUpdates() {
        if let simulatedProvider = locationProvider as? SimulatedLocationProvider {
            self.cancellable = simulatedProvider.$lastLocation
                .compactMap { $0?.clLocation }
                .sink { [weak self] location in
                    self?.updateLocation(location)
                }
        } else {
            // Setup for real location provider if needed
        }
    }
}
