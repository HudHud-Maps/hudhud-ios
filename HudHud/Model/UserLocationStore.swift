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
    @Published private(set) var currentUserLocation: CLLocation?

    private let location: Location

    private var monitorLocationTask: Task<Void, Error>?
    private var monitorPermissionsTask: Task<Void, Never>?

    // MARK: - Lifecycle

    init(location: Location) {
        self.location = location
    }

    deinit {
        self.monitorLocationTask?.cancel()
        self.monitorPermissionsTask?.cancel()
    }

    // MARK: - Internal

    // this can be called multiple times, we need to make sure that tasks are only created when needed
    func start() {
        if self.monitorLocationTask == nil {
            self.monitorLocationTask = Task {
                // this function should never throw
                try await self.startMonitoringUserLocation()
            }
        }
        if self.monitorPermissionsTask == nil {
            self.monitorPermissionsTask = Task {
                await self.startMonitoringUserPermission()
            }
        }
    }
}

private extension UserLocationStore {

    private func startMonitoringUserPermission() async {
        self.isLocationPermissionEnabled = self.location.authorizationStatus.allowed
        for await event in await self.location.startMonitoringAuthorization() {
            self.isLocationPermissionEnabled = event.authorizationStatus.allowed
        }
    }

    private func startMonitoringUserLocation() async throws {
        let isAllowed = await (try? self.location.requestPermission(.whenInUse).allowed) ?? false
        guard isAllowed else { return }
        for await event in try await self.location.startMonitoringLocations() {
            if let location = event.location {
                self.currentUserLocation = location
            }
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
