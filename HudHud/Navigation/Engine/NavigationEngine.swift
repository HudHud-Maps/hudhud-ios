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

    private let configuration: NavigationConfig
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
        self.configuration = configuration
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
        self.locationEngine.swithcMode(to: .snapped)
        self.eventsSubject.send(.navigationStarted)
        self.horizonEngine.startMonitoring(route: route)
    }

    func stopNavigation() {
        self.ferrostarCore.stopNavigation()
        self.activeRoute = nil
        self.state = nil
        self.eventsSubject.send(.navigationEnded)
        self.locationEngine.swithcMode(to: .raw)
        self.horizonEngine.stopMonitoring()
    }

    func toggleMute() {
        self.spokenInstructionObserver.toggleMute()
    }
}

private extension NavigationEngine {
    func onStateChange(_ newState: NavigationState) {
        if let snappedLocation = newState.tripState.navigationInfo?.location {
            self.useSnappedLocation(snappedLocation.clLocation)
            self.horizonEngine.processLocation(snappedLocation.clLocation)
        }
        self.eventsSubject.send(.stateChanged(newState))
    }

    func useSnappedLocation(_ newLocation: CLLocation) {
        self.locationEngine.update(withSnaplocation: newLocation)
        self.eventsSubject.send(.snappedLocationUpdated(newLocation))
    }

    func setupFerrostarCore() {
        self.ferrostarCore.delegate = self.navigationDelegate
        self.ferrostarCore.spokenInstructionObserver = self.spokenInstructionObserver
        self.ferrostarCore.minimumTimeBeforeRecalculaton = 5
    }

    func observeFerrostarState() {
        self.ferrostarCore
            .objectWillChange
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

    func observeLocationEngineState() {
        self.locationEngine.events
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] event in
                self?.handleLocationEngineEvents(event)
            }
            .store(in: &self.cancellables)
    }

    func handleLocationEngineEvents(_ newEvent: LocationEngineEvent) {
        switch newEvent {
        case .locationUpdated:
            break
        case let .modeChanged(newMode):
            Logger.locationEngine.debug("Location engine mode changed to \(String(describing: newMode))")
        case let .providerChanged(newType):
            Logger.locationEngine.debug("Location engine mode changed to \(String(describing: newType))")
            self.ferrostarCore = FerrostarCore(
                customRouteProvider: self.configuration.routeProvider,
                locationProvider: self.locationEngine.locationProvider,
                navigationControllerConfig: self.configuration.toFerrostarConfig(),
                annotation: self.annotationPublisher
            )
            self.setupFerrostarCore()
        }
    }
}
