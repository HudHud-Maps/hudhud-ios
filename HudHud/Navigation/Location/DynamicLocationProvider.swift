//
//  DynamicLocationProvider.swift
//  HudHud
//
//  Created by Ali Hilal on 03/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Combine
import FerrostarCore
import FerrostarCoreFFI
import Foundation
import MapLibre

public final class HudHudLocationManager: NSObject, MLNLocationManager, @unchecked Sendable {

    // MARK: Properties

    public var delegate: (any MLNLocationManagerDelegate)?
    public var authorizationStatus: CLAuthorizationStatus
    public var headingOrientation: CLDeviceOrientation = .portrait

    private let locationProvider: LocationProviding
    private var useRawUpdates = true
    private var cancellable: AnyCancellable?

    // MARK: Computed Properties

    private(set) var lastLocation: CLLocation? {
        didSet {
            guard let lastLocation else { return }
            DispatchQueue.main.async {
                self.delegate?.locationManager(self, didUpdate: [lastLocation])
            }
        }
    }

    // MARK: Lifecycle

    public init(locationProvider: LocationProviding) {
        self.locationProvider = locationProvider
        self.authorizationStatus = locationProvider.authorizationStatus
        super.init()

        var publisher: Published<FerrostarCoreFFI.UserLocation?>.Publisher?
        if let locationProvider = locationProvider as? SimulatedLocationProvider {
            publisher = locationProvider.$lastLocation
        }
        if let locationProvider = locationProvider as? CoreLocationProvider {
            publisher = locationProvider.$lastLocation
        }

        self.cancellable = publisher?
            .compactMap { $0?.clLocation }
            .receive(on: DispatchQueue.main)
            .drop(while: { [weak self] _ in self?.useRawUpdates == false })
            .sink { [weak self] location in
                guard let self else { return }
                self.lastLocation = location
            }
    }

    // MARK: Functions

    public func useSnappedLocation(_ location: CLLocation) {
        self.useRawUpdates = false
        self.lastLocation = location
    }

    public func useRawLocation() {
        self.useRawUpdates = true
    }

    // MARK: - MLNLocationManager

    public func startUpdatingLocation() {
        // This has to be async dispatched or else the map view will not update immediately if the camera is set to
        // follow the user's location. This leads to some REALLY (unbearably) bad artifacts. We should find a better
        // solution for this at some point. This is the reason for the @unchecked Sendable conformance by the way (so
        // that we don't get a warning about using non-sendable self; it should be safe though).
        DispatchQueue.main.async {
            if let lastLocation = self.lastLocation {
                self.delegate?.locationManager(self, didUpdate: [lastLocation])
            }
        }
    }

    public func stopUpdatingLocation() {
        self.locationProvider.stopUpdating()
    }

    public func requestAlwaysAuthorization() {}
    public func requestWhenInUseAuthorization() {}
    public func startUpdatingHeading() {}
    public func stopUpdatingHeading() {}
    public func dismissHeadingCalibrationDisplay() {}
}
