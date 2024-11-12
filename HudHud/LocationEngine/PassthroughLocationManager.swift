//
//  PassthroughLocationManager.swift
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

public final class PassthroughLocationManager: NSObject, MLNLocationManager, @unchecked Sendable {

    // MARK: Properties

    public var delegate: (any MLNLocationManagerDelegate)?
    public var authorizationStatus: CLAuthorizationStatus
    public var headingOrientation: CLDeviceOrientation = .portrait

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

    init(authorizationStatus: CLAuthorizationStatus,
         headingOrientation: CLDeviceOrientation,
         lastLocation: CLLocation? = nil) {
        self.authorizationStatus = authorizationStatus
        self.headingOrientation = headingOrientation
        self.lastLocation = lastLocation
    }

    // MARK: Functions

    // MARK: - MLNLocationManager

    public func startUpdatingLocation() {
        DispatchQueue.main.async {
            if let lastLocation = self.lastLocation {
                self.delegate?.locationManager(self, didUpdate: [lastLocation])
            }
        }
    }

    public func stopUpdatingLocation() {}

    public func requestAlwaysAuthorization() {}
    public func requestWhenInUseAuthorization() {}
    public func startUpdatingHeading() {}
    public func stopUpdatingHeading() {}
    public func dismissHeadingCalibrationDisplay() {}

    func updateLocation(_ location: CLLocation) {
        self.lastLocation = location
    }
}
