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
class UserLocationStore: ObservableObject {

    @Published private(set) var isLocationPermissionEnabled: Bool = false
    @Published private(set) var currentUserLocation: CLLocation?

    private let location: Location

    private var monitorLocationTask: Task<Void, Error>?
    private var monitorPermissionsTask: Task<Void, Never>?

    func lastKnownLocationOrWaitUntilPermissionIsGranted() async -> CLLocation {
        if let currentUserLocation {
            return currentUserLocation
        }
        // if we do not have the current location, we wait for it here
        return await withCheckedContinuation { promise in
            var subscription: AnyCancellable?
            subscription = self.$currentUserLocation
                .compactMap { $0 } // remove the nil
                .first() // only allow one value and end the subscription after that
                .sink { newestLocation in
                    promise.resume(returning: newestLocation)
                    subscription?.cancel()
                }
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

    // MARK: - Private

    private func startMonitoringUserPermission() async {
        self.isLocationPermissionEnabled = self.location.authorizationStatus.allowed
        for await event in await self.location.startMonitoringAuthorization() {
            self.isLocationPermissionEnabled = event.authorizationStatus.allowed
        }
    }
}

extension UserLocationStore {
    static let preview = UserLocationStore(location: .preview)
}

extension Location {
    static func make() -> Location {
        let location = Location() // swiftlint:disable:this location_usage
        location.accuracy = .bestForNavigation
        return location
    }
}

// MARK: - Location + Previewable

extension Location {

    static let preview = Location() // swiftlint:disable:this location_usage
}
