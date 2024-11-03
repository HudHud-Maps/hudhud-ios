//
//  LocationServicesDiagnostic.swift
//  HudHud
//
//  Created by Ali Hilal on 03/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import MapLibre

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

    private func checkInfoPlistPermissions() {
        print("📍 Checking Info.plist permissions...")

        let whenInUse = Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") != nil
        let always = Bundle.main.object(forInfoDictionaryKey: "NSLocationAlwaysUsageDescription") != nil

        print("- When In Use Permission String: \(whenInUse ? "✅" : "❌")")
        print("- Always Permission String: \(always ? "✅" : "❌")")
    }

    private func checkLocationServicesStatus() {
        print("\n📍 Checking Location Services Status...")

        print("- Location Services Enabled: \(CLLocationManager.locationServicesEnabled() ? "✅" : "❌")")

        let authStatus = CLLocationManager.authorizationStatus()
        print("- Authorization Status: \(self.authStatusString(authStatus))")

        if #available(iOS 14.0, *), let accuracy = self.mapView.locationManager.accuracyAuthorization?() {
            print("- Accuracy Authorization: \(accuracyString(accuracy))")
        }
    }

    private func checkMapViewConfiguration() {
        print("\n📍 Checking MapView Configuration...")

        print("- showsUserLocation: \(self.mapView.showsUserLocation ? "✅" : "❌")")
        print("- userLocationVisible: \(self.mapView.isUserLocationVisible ? "✅" : "❌")")
        print("- User Location Valid: \(CLLocationCoordinate2DIsValid(self.mapView.userLocation?.coordinate ?? kCLLocationCoordinate2DInvalid) ? "✅" : "❌")")
        print("- Tracking Mode: \(self.trackingModeString(self.mapView.userTrackingMode))")
    }

    private func checkLocationUpdates() {
        print("\n📍 Checking Location Updates...")

        if let location = mapView.userLocation?.location {
            print("- Last Location: ✅")
            print("  Coordinate: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            print("  Accuracy: \(location.horizontalAccuracy)m")
            print("  Timestamp: \(location.timestamp)")
        } else {
            print("- Last Location: ❌ No location updates received")
        }
    }

    // Helper functions to convert enums to strings
    private func authStatusString(_ status: CLAuthorizationStatus) -> String {
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
    private func accuracyString(_ accuracy: CLAccuracyAuthorization) -> String {
        switch accuracy {
        case .fullAccuracy: return "✅ Full Accuracy"
        case .reducedAccuracy: return "⚠️ Reduced Accuracy"
        @unknown default: return "❓ Unknown"
        }
    }

    private func trackingModeString(_ mode: MLNUserTrackingMode) -> String {
        switch mode {
        case .none: return "None"
        case .follow: return "Follow"
        case .followWithHeading: return "Follow with Heading"
        case .followWithCourse: return "Follow with Course"
        @unknown default: return "Unknown"
        }
    }
}
