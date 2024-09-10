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

    // MARK: Properties

    @Published private(set) var isLocationPermissionEnabled: Bool = false

    private var currentUserLocation: CLLocation?

    private let location: Location

    private var monitorPermissionsTask: Task<Void, Never>?
    private var updateLocationSubscription: AnyCancellable?
    private var didBecomeActiveSubscription: AnyCancellable?

    // MARK: Lifecycle

    init(location: Location) {
        self.location = location
    }

    deinit {
        self.monitorPermissionsTask?.cancel()
    }

    // MARK: Functions

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

    // MARK: - Internal

    // this can be called multiple times, we need to make sure that tasks are only created when needed
    func startMonitoringPermissions() {
        if self.monitorPermissionsTask == nil {
            Task {
                let isAllowed = await (try? self.location.requestPermission(.whenInUse).allowed) ?? false
                if isAllowed {
                    await self.updateToLatestLocation()
                }
            }

            self.monitorPermissionsTask = Task {
                await self.startMonitoringUserPermission()
            }
            self.updateUserLocationEvery90Seconds()
            self.updateUserLocationAfterBecomingActive()
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

    func updateUserLocationEvery90Seconds() {
        self.updateLocationSubscription = Timer.publish(every: 90, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, self.isLocationPermissionEnabled else { return }
                Task {
                    await self.updateToLatestLocation()
                }
            }
    }

    func updateUserLocationAfterBecomingActive() {
        self.didBecomeActiveSubscription = NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                guard let self, self.isLocationPermissionEnabled else { return }
                Task {
                    await self.updateToLatestLocation()
                }
            }
    }

    func updateToLatestLocation() async {
        if let newLocation = try? await self.location.requestLocation().location {
            self.currentUserLocation = newLocation
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
