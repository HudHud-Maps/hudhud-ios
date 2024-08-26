//
//  UserLocationStore.swift
//  HudHud
//
//  Created by Naif Alrashed on 20/08/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Combine
import CoreLocation
import Foundation
import OSLog
import SwiftLocation
import SwiftUI

// MARK: - UserLocationStore

@MainActor
final class UserLocationStore: ObservableObject {

    @Published private(set) var isLocationPermissionEnabled: Bool = false
    private var currentUserLocation: CLLocation?

    private let location: Location

    private var monitorPermissionsTask: Task<Void, Never>?

    func location(allowCached: Bool = true) async -> CLLocation? {
        if let currentUserLocation,
           allowCached,
           currentUserLocation.timestamp.advanced(by: .minutes(2)) > Date.now {
            return currentUserLocation
        }
        if self.location.authorizationStatus == .notDetermined {
            let status = try? await location.requestPermission(.whenInUse)
            if status == nil {
                return nil
            }
        }
        if !self.location.authorizationStatus.allowed {
            return nil
        }
        let newLocation = try? await location.requestLocation().location
        if let newLocation {
            self.currentUserLocation = newLocation
            return newLocation
        }
        return nil
    }

    // MARK: - Lifecycle

    init(location: Location) {
        self.location = location
    }

    deinit {
        self.monitorPermissionsTask?.cancel()
    }

    // MARK: - Internal

    // this can be called multiple times, we need to make sure that tasks are only created when needed
    func start() {
        if self.monitorPermissionsTask == nil {
            Task {
                try? await self.location.requestPermission(.whenInUse).allowed
            }
            self.monitorPermissionsTask = Task {
                await self.startMonitoringUserPermission()
            }
        }
    }
}

// MARK: - Private

private extension UserLocationStore {

    func startMonitoringUserPermission() async {
        self.isLocationPermissionEnabled = self.location.authorizationStatus.allowed
        for await event in await self.location.startMonitoringAuthorization() {
            self.isLocationPermissionEnabled = event.authorizationStatus.allowed
        }
    }
}

// MARK: - Previewable

extension UserLocationStore: Previewable {
    static let storeSetUpForPreviewing = UserLocationStore(location: .storeSetUpForPreviewing)
}

// MARK: - Location + Previewable

extension Location: Previewable {
    static let storeSetUpForPreviewing = Location() // swiftlint:disable:this location_usage
}

private extension TimeInterval {
    static func minutes(_ minutes: UInt) -> Self {
        TimeInterval(60 * minutes)
    }
}
