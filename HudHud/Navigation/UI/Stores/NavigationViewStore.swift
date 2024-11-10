//
//  NavigationViewStore.swift
//  HudHud
//
//  Created by Ali Hilal on 04/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Combine
import CoreLocation
import FerrostarCore
import Foundation
import SwiftUI
import UIKit

extension NavigationStore.State {
    var isNavigating: Bool {
        status == .navigating
    }
}

// MARK: - NavigationStore

@MainActor
@Observable
final class NavigationStore {

    // MARK: Nested Types

    struct State: Equatable {

        // MARK: Nested Types

        enum Status {
            case idle
            case navigating
            case cancelled
            case arrived
            case failed
        }

        // MARK: Properties

        var status: Status
        var speedLimit: Measurement<UnitSpeed>?
        var navigationAlert: NavigationAlert?

        var isMuted: Bool = false
        var tripProgress: TripProgress?
    }

    enum Action {
        case startNavigation //
        case stopNavigation
        case toggleMute
    }

    // MARK: Properties

    var state = State(status: .idle)

    private var cancellables = Set<AnyCancellable>()
    private let navigationEngine: NavigationEngine
    private let locationEngine: LocationEngine
    private let routesPlanMapDrawer: RoutesPlanMapDrawer

    // MARK: Computed Properties

    var navigationState: NavigationState? {
        self.navigationEngine.state
    }

    var locationManager: PassthroughLocationManager {
        self.locationEngine.locationManager
    }

    var lastKnownLocation: CLLocation? {
        self.locationEngine.lastLocation
    }

    // MARK: Lifecycle

    init(
        navigationEngine: NavigationEngine,
        locationEngine: LocationEngine,
        routesPlanMapDrawer: RoutesPlanMapDrawer

    ) {
        self.navigationEngine = navigationEngine
        self.locationEngine = locationEngine
        self.routesPlanMapDrawer = routesPlanMapDrawer
        self.setupSubscriptions()
    }

    // MARK: Functions

    func execute(_ action: Action) {
        switch action {
        case .startNavigation:
            satrtNavigation()

        case .stopNavigation:
            stopNavigation()

        case .toggleMute:
            self.navigationEngine.toggleMute()
            self.state.isMuted.toggle()
        }
    }
}

private extension NavigationStore {

    func stopNavigation() {
        // capture state before stopping
        let isNavigating = self.state.status == .navigating
        let hasArrived = self.navigationState?.tripState.isComplete ?? false
        self.navigationEngine.stopNavigation()
        if isNavigating {
            self.state.status = .cancelled
        }

        if hasArrived {
            self.state.status = .arrived
        }
        self.state.navigationAlert = nil
        UIApplication.shared.isIdleTimerDisabled = false
    }

    func satrtNavigation() {
        guard let route = routesPlanMapDrawer.selectedRoute else {
            return
        }

        do {
            try self.decideWhichLocationProviderToUse(route: route) {
                try self.navigationEngine.startNavigation(route: route)
                self.state.status = .navigating
            }
        } catch {
            self.state.status = .failed
        }
        UIApplication.shared.isIdleTimerDisabled = true
    }

    func setupSubscriptions() {
        self.navigationEngine
            .events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleNavigationEvent(event)
            }
            .store(in: &self.cancellables)

        self.navigationEngine
            .horizonEvents
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleHorizonEvent(event)
            }.store(in: &self.cancellables)
    }

    func decideWhichLocationProviderToUse(route: Route, action: () throws -> Void) rethrows {
        if DebugStore().simulateRide {
            // give a chance to camera movment
            self.locationEngine.switchToSimulated(route: route)
            try action()
            self.locationEngine.locationProvider.stopUpdating()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.locationEngine.locationProvider.startUpdating()
            }
        } else {
            self.locationEngine.switchToStandard()
            try action()
        }
    }

    func handleNavigationStateChange(_ newState: NavigationState) {
        self.state.tripProgress = newState.tripState.currentProgress
        switch newState.tripState {
        case .idle:
            self.state.status = .idle
        case .navigating:
            self.state.status = .navigating
        case .complete:
            self.state.status = .arrived
        }
    }

    func handleNavigationEvent(_ event: NavigationEvent) {
        switch event {
        case .navigationStarted:
            break
        case .navigationEnded:
            break
        case let .stateChanged(navigationState):
            self.handleNavigationStateChange(navigationState)
        case .routeUpdated:
            break
        case .stepChanged:
            break
        case let .speedLimitChanged(speedLimit):
            self.state.speedLimit = speedLimit
        case .snappedLocationUpdated:
            break
        case .error:
            self.state.status = .failed
        }
    }

    func handleHorizonEvent(_ event: HorizionEvent) {
        switch event {
        case let .approachingSpeedCamera(camera, distance):
            let speedCamAlertDistance = SpeedCameraAlertConfig.default.initialAlertDistance
            let progress = (1 - (distance.meters / speedCamAlertDistance.meters)) * 100
            let clampedProgress = max(0, min(100, progress))
            withAnimation(.easeInOut(duration: 0.15)) {
                self.state.navigationAlert = NavigationAlert(
                    id: camera.id,
                    progress: clampedProgress,
                    alertType: .speedCamera(camera),
                    alertDistance: Int(distance.meters)
                )
            }
        case let .passedSpeedCamera(camera):
            if self.state.navigationAlert?.id == camera.id {
                self.state.navigationAlert = nil
            }

            self.state.navigationAlert = nil
        case let .approachingTrafficIncident(incident, distance):
            let incidentAlertDistance = TrafficIncidentAlertConfig.default.initialAlertDistance
            let progress = (1 - (distance.meters / incidentAlertDistance.meters)) * 100
            let clampedProgress = max(0, min(100, progress))
            self.state.navigationAlert = NavigationAlert(
                id: incident.id,
                progress: clampedProgress,
                alertType: .carAccident(incident),
                alertDistance: Int(distance.meters)
            )
        case let .passedTrafficIncident(incident):
            if self.state.navigationAlert?.id == incident.id {
                self.state.navigationAlert = nil
            }
        case .enteredSpeedZone:
            break
        case .exitedSpeedZone:
            break
        }
    }
}
