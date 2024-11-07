//
//  NavigationEngine.swift
//  HudHud
//
//  Created by Ali Hilal on 04/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Combine
import CoreLocation
import FerrostarCore
import FerrostarCoreFFI
import Foundation

// MARK: - NavigationError

enum NavigationError: Error {
    case invalidState
}

// MARK: - NavigationEvent

enum NavigationEvent {
    case navigationStarted
    case navigationEnded
    case stateChanged(NavigationState)
    case routeUpdated(Route)
    case stepChanged(RouteStep)
    case speedLimitChanged(Measurement<UnitSpeed>?)
    case snappedLocationUpdated(CLLocation)
    case error(NavigationError)
}

// MARK: - NavigationEngine

@Observable
final class NavigationEngine {

    // MARK: Properties

    private(set) var activeRoute: Route?
    private(set) var spokenInstructionObserver: SpokenInstructionObserver

    private var ferrostarCore: FerrostarCore
    private let navigationDelegate: NavigationDelegate
    private let annotationPublisher: AnnotationPublisher<ValhallaExtendedOSRMAnnotation>
    private let eventsSubject = PassthroughSubject<NavigationEvent, Never>()
    private let locationEngine: LocationEngine
    private var cancellables: Set<AnyCancellable> = []

    private let horizonEngine: HorizonEngine

    // MARK: Computed Properties

    var events: AnyPublisher<NavigationEvent, Never> {
        self.eventsSubject.eraseToAnyPublisher()
    }

    var horizonEvents: AnyPublisher<HorizionEvent, Never> {
        self.horizonEngine.events.eraseToAnyPublisher()
    }

    private(set) var state: NavigationState? {
        didSet {
            guard let state, state != oldValue else { return }
            self.onStateChange(state)
        }
    }

    // MARK: Lifecycle

    init(configuration: NavigationConfig) {
        self.navigationDelegate = NavigationDelegate()
        self.annotationPublisher = .valhallaExtendedOSRM()
        self.spokenInstructionObserver = .initAVSpeechSynthesizer(isMuted: false)
        self.locationEngine = configuration.locationEngine
        self.horizonEngine = HorizonEngine(configuration: configuration)

        self.ferrostarCore = FerrostarCore(
            customRouteProvider: configuration.routeProvider,
            locationProvider: self.locationEngine.locationProvider,
            navigationControllerConfig: configuration.toFerrostarConfig(),
            annotation: self.annotationPublisher
        )

        self.setupFerrostarCore()
        self.observeFerrostarState()
        self.observeLocationEngineState()
    }

    // MARK: Functions

    func startNavigation(route: Route) throws {
        self.activeRoute = route
        try self.ferrostarCore.startNavigation(route: route)
        self.eventsSubject.send(.navigationStarted)
    }

    func stopNavigation() {
        self.ferrostarCore.stopNavigation()
        self.activeRoute = nil
        self.state = nil
        self.eventsSubject.send(.navigationEnded)
    }

    func toggleMute() {
        self.spokenInstructionObserver.toggleMute()
    }

    private func onStateChange(_ newState: NavigationState) {
        if let newLocationMode = decideWhichLocationModeToUse(from: newState) {
            self.locationEngine.swithcMode(to: newLocationMode)
        }

        if let snappedLocation = newState.tripState.navigationInfo?.location {
            self.useSnappedLocation(snappedLocation.clLocation)
        }

        self.eventsSubject.send(.stateChanged(newState))
    }

    private func useSnappedLocation(_ newLocation: CLLocation) {
        self.locationEngine.update(withSnaplocation: newLocation)
        self.eventsSubject.send(.snappedLocationUpdated(newLocation))
    }

    private func decideWhichLocationModeToUse(from newState: NavigationState) -> LocationMode? {
        let currentMode = self.locationEngine.currentMode
        let shouldUseSnappedLocation = newState.isNavigating

        let newMode: LocationMode = shouldUseSnappedLocation ? .snapped : .raw

        return newMode != currentMode ? newMode : nil
    }

    private func setupFerrostarCore() {
        self.ferrostarCore.delegate = self.navigationDelegate
        self.ferrostarCore.spokenInstructionObserver = self.spokenInstructionObserver
        self.ferrostarCore.minimumTimeBeforeRecalculaton = 5
    }

    private func observeFerrostarState() {
        self.ferrostarCore.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self,
                      let newState = self.ferrostarCore.state else { return }
                self.state = newState
            }
            .store(in: &self.cancellables)

        self.annotationPublisher
            .$speedLimit
            .sink { [weak self] sppedLimit in
                self?.eventsSubject.send(.speedLimitChanged(sppedLimit))
            }.store(in: &self.cancellables)
    }

    private func observeLocationEngineState() {
        self.locationEngine.events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
            }
            .store(in: &self.cancellables)
    }

    private func handleLocationEngineEvents(_ newEvent: LocationEngineEvent) {
        switch newEvent {
        case .locationUpdated:
            break
        case .modeChanged:
            break
        case .providerChanged:
            break // switch the navigation stuff
        }
    }
}
