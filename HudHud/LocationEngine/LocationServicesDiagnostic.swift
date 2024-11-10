//
//  LocationServicesDiagnostic.swift
//  HudHud
//
//  Created by Ali Hilal on 03/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import MapLibre
import OSLog

// MARK: - LocationServicesDiagnostic

final class LocationServicesDiagnostic {

    // MARK: Properties

    let mapView: MLNMapView

    // MARK: Lifecycle

    init(mapView: MLNMapView) {
        self.mapView = mapView
    }

    // MARK: Functions

    func runDiagnostics() {
        self.checkInfoPlistPermissions()

        self.checkLocationServicesStatus()

        self.checkMapViewConfiguration()

        self.checkLocationUpdates()
    }
}

private extension LocationServicesDiagnostic {

    func checkInfoPlistPermissions() {
        Logger.diagnostics.notice("📍 Checking Info.plist permissions...")

        let whenInUse = Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") != nil
        let always = Bundle.main.object(forInfoDictionaryKey: "NSLocationAlwaysUsageDescription") != nil

        Logger.diagnostics.notice("- When In Use Permission String: \(whenInUse ? "✅" : "❌")")
        Logger.diagnostics.notice("- Always Permission String: \(always ? "✅" : "❌")")
    }

    func checkLocationServicesStatus() {
        Logger.diagnostics.notice("\n📍 Checking Location Services Status...")

        Logger.diagnostics.notice("- Location Services Enabled: \(CLLocationManager.locationServicesEnabled() ? "✅" : "❌")")

        let authStatus = CLLocationManager().authorizationStatus
        Logger.diagnostics.notice("- Authorization Status: \(self.authStatusString(authStatus))")

        if #available(iOS 14.0, *), let accuracy = self.mapView.locationManager.accuracyAuthorization?() {
            Logger.diagnostics.notice("- Accuracy Authorization: \(self.accuracyString(accuracy))")
        }
    }

    func checkMapViewConfiguration() {
        Logger.diagnostics.notice("\n📍 Checking MapView Configuration...")

        Logger.diagnostics.notice("- showsUserLocation: \(self.mapView.showsUserLocation ? "✅" : "❌")")
        Logger.diagnostics.notice("- userLocationVisible: \(self.mapView.isUserLocationVisible ? "✅" : "❌")")
        Logger.diagnostics.notice("- User Location Valid: \(CLLocationCoordinate2DIsValid(self.mapView.userLocation?.coordinate ?? kCLLocationCoordinate2DInvalid) ? "✅" : "❌")")
        Logger.diagnostics.notice("- Tracking Mode: \(self.trackingModeString(self.mapView.userTrackingMode))")
    }

    func checkLocationUpdates() {
        Logger.diagnostics.notice("\n📍 Checking Location Updates...")

        if let location = mapView.userLocation?.location {
            Logger.diagnostics.notice("- Last Location: ✅")
            Logger.diagnostics.notice("  Coordinate: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            Logger.diagnostics.notice("  Accuracy: \(location.horizontalAccuracy)m")
            Logger.diagnostics.notice("  Timestamp: \(location.timestamp)")
        } else {
            Logger.diagnostics.notice("- Last Location: ❌ No location updates received")
        }
    }

    // Helper functions to convert enums to strings
    func authStatusString(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .authorizedWhenInUse: return "✅ Authorized When In Use"
        case .authorizedAlways: return "✅ Authorized Always"
        case .denied: return "❌ Denied"
        case .restricted: return "❌ Restricted"
        case .notDetermined: return "⚠️ Not Determined"
        @unknown default: return "❓ Unknown"
        }
    }

    @available(iOS 14.0, *)
    func accuracyString(_ accuracy: CLAccuracyAuthorization) -> String {
        switch accuracy {
        case .fullAccuracy: return "✅ Full Accuracy"
        case .reducedAccuracy: return "⚠️ Reduced Accuracy"
        @unknown default: return "❓ Unknown"
        }
    }

    func trackingModeString(_ mode: MLNUserTrackingMode) -> String {
        switch mode {
        case .none: return "None"
        case .follow: return "Follow"
        case .followWithHeading: return "Follow with Heading"
        case .followWithCourse: return "Follow with Course"
        @unknown default: return "Unknown"
        }
    }
}
