//
//  NavigationViewStore.swift
//  HudHud
//
//  Created by Ali Hilal on 04/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Combine
import Foundation

// @MainActor
// final class SpeedCameraStore: ObservableObject {
//    @Published private(set) var activeCamera: SpeedCamera?
//    @Published private(set) var upcomingCameras: [SpeedCamera] = []
//
//    private var cancellables = Set<AnyCancellable>()
//    private let navigationEngine: NavigationEngine
//
//    init(navigationEngine: NavigationEngine) {
//        self.navigationEngine = navigationEngine
//
//        // Subscribe to navigation events
//        navigationEngine.navigationPublisher
//            .compactMap { event -> SpeedCamera? in
//                if case .horizonEvent(.speedCamera(let camera)) = event {
//                    return camera
//                }
//                return nil
//            }
//            .sink { [weak self] camera in
//                self?.handleSpeedCamera(camera)
//            }
//            .store(in: &cancellables)
//    }
//
//    func reportIncorrectCamera(_ camera: SpeedCamera) async {
//        // Handle incorrect camera report
//    }
// }

import CoreLocation
import FerrostarCore
import UIKit

// MARK: - SpeedCameraAlert

// ui thing
struct SpeedCameraAlert: Equatable {}

// MARK: - NavigationStore

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
            case stopped
            case failed
        }

        // MARK: Properties

        var status: Status
        var speedLimit: Measurement<UnitSpeed>?
        let currentCamera: SpeedCamera?
        let distanceToCamera: Measurement<UnitLength>?
        var isMuted: Bool = false

        // let activeHorizonFeatures: Set<HorizonFeature>
    }

    enum Action {
        case startNavigation
        case stopNavigation
        case toggleMute
    }

    // MARK: Properties

    var state: State = .init(status: .idle, currentCamera: nil, distanceToCamera: nil)

    private var cancellables = Set<AnyCancellable>()
    private let navigationEngine: NavigationEngine
    private let locationEngine: LocationEngine
    private let routesPlanMapDrawer: RoutesPlanMapDrawer

    // MARK: Computed Properties

    var navigationState: NavigationState? {
        self.navigationEngine.state
    }

    //    private(set) var speedCameraAlert: SpeedCameraAlert?
    //    var currentCamera: SpeedCamera?
    //    var distanceToCamera: Measurement<UnitLength>?
    //    var isApproachingCamera: Bool = false
    //    private(set) var activeHorizonFeatures: Set<HorizonFeature> = []

    var currentState: NavigationState? {
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
            self.satrtNavigation()

        case .stopNavigation:
            self.stopNavigation()

        case .toggleMute:
            // mute engine
            self.state.isMuted.toggle()
        }
    }

    private func stopNavigation() {
        self.navigationEngine.stopNavigation()
        self.state.status = .stopped
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func reportIncorrectCamera(_: SpeedCamera) {}

    private func satrtNavigation() {
        guard let route = routesPlanMapDrawer.selectedRoute else {
            print("No route selected")
            return
        }

        do {
            try self.navigationEngine.startNavigation(route: route)
            self.decideWhichLocationProviderToUse(route: route)
            self.state.status = .navigating
        } catch {
            self.state.status = .failed
        }
        UIApplication.shared.isIdleTimerDisabled = true
    }

    private func setupSubscriptions() {
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

    private func decideWhichLocationProviderToUse(route: Route) {
        if DebugStore().simulateRide {
            // give a chance to camera movment
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.locationEngine.switchToSimulated(route: route)
            }
        } else {
            self.locationEngine.switchToStandard()
        }
    }

    private func handleNavigationStateChange(_: NavigationState) {}

    private func handleNavigationEvent(_ event: NavigationEvent) {
        switch event {
        case .navigationStarted:
            break
        case .navigationEnded:
            break
        case let .stateChanged(navigationState):
            self.handleNavigationStateChange(navigationState)
        case let .routeUpdated(newRoute):
            break
        case let .stepChanged(newStep):
            break
        case let .speedLimitChanged(speedLimit):
            self.state.speedLimit = speedLimit
        case let .snappedLocationUpdated(snappedLocation):
            break
        case let .error(error):
            break
        }
    }

    private func handleHorizonEvent(_: HorizionEvent) {}
}

// struct SpeedCameraMapLayer: StyleLayerDefinition {
//    let camera: SpeedCamera
//
//    var layerProperties: [String: Any] {
//    }
//
//    var source: SourceDefinition {
//    }
// }
//
