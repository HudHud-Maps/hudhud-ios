//
//  NavigationEngine.swift
//  HudHud
//
//  Created by Ali Hilal on 17/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import Combine
import FerrostarCore
import FerrostarCoreFFI
import Foundation
import MapLibre
import MapLibreSwiftDSL
import OSLog

// MARK: - NavigationEngine

final class NavigationEngine {

    // MARK: Properties

    var navigationEvents: PassthroughSubject<NavigationEvent, Never> = .init()

    private(set) var provider: LocationProviding

    private var ferrostarCore: FerrostarCore

    private let spokenInstructionObserver = AVSpeechSpokenInstructionObserver(isMuted: false)

    private let config = SwiftNavigationControllerConfig(
        stepAdvance: .relativeLineStringDistance(
            minimumHorizontalAccuracy: 32, automaticAdvanceDistance: 10
        ),
        routeDeviationTracking: .staticThreshold(
            minimumHorizontalAccuracy: 25, maxAcceptableDeviation: 20
        ), snappedLocationCourseFiltering: .snapToRoute
    )

    private var cancellables = Set<AnyCancellable>()

    // MARK: Computed Properties

    var isNavigating: Bool {
        self.ferrostarCore.isNavigating
    }

    var currentLocation: CLLocation? {
        self.ferrostarCore.locationProvider.lastLocation?.clLocation
    }

    var authorizationStatus: CLAuthorizationStatus {
        self.ferrostarCore.locationProvider.authorizationStatus
    }

    // MARK: Lifecycle

    init() {
        switch LocationProviderKind.current {
        case .simulated:
            let simulated = SimulatedLocationProvider(coordinate: .riyadh)
            simulated.warpFactor = 20
            self.provider = simulated
        case .coreLocation:
            self.provider = CoreLocationProvider(
                activityType: .automotiveNavigation,
                allowBackgroundLocationUpdates: true
            )
            self.provider.startUpdating()
        }

        self.ferrostarCore = FerrostarCore(
            customRouteProvider: GraphHopperRouteProvider(),
            locationProvider: self.provider,
            navigationControllerConfig: self.config
        )

        self.ferrostarCore.spokenInstructionObserver = self.spokenInstructionObserver
        self.ferrostarCore.delegate = self
    }

    // MARK: Functions

    func switchLocationProvider(to providerKind: LocationProviderKind) {
        switch providerKind {
        case .simulated:
            let simulated = SimulatedLocationProvider(coordinate: .riyadh)
            simulated.warpFactor = 20
            self.provider = simulated
        case .coreLocation:
            self.provider = CoreLocationProvider(
                activityType: .automotiveNavigation,
                allowBackgroundLocationUpdates: true
            )
            self.provider.startUpdating()
        }

        self.ferrostarCore = FerrostarCore(
            customRouteProvider: GraphHopperRouteProvider(),
            locationProvider: self.provider,
            navigationControllerConfig: self.config
        )

        self.ferrostarCore.spokenInstructionObserver = self.spokenInstructionObserver
        self.ferrostarCore.delegate = self
    }

    func startNavigation(on route: Route) {
        do {
            self.startSimulationEngineIfNeeded(on: route)
            try self.ferrostarCore.startNavigation(route: route, config: self.config)
        } catch {
            print("satrtNavigation failed: \(error.localizedDescription)")
        }
    }

    func stopNavigation() {
        self.ferrostarCore.stopNavigation()
    }

    func startSimulationEngineIfNeeded(on route: Route) {
        if let simulated = ferrostarCore.locationProvider as? SimulatedLocationProvider {
            try? simulated.setSimulatedRoute(route, resampleDistance: 5)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                simulated.startUpdating()
            }
        }
    }

    func listenForFerrostarEvents() {
        self.ferrostarCore.$state
            .compactMap { $0?.tripState }
            .removeDuplicates()
            .sink { [weak self] newTripState in
                self?.handleTripStateChange(newTripState)
            }
            .store(in: &self.cancellables)
    }

    private func handleTripStateChange(_ newState: TripState) {
        switch newState {
        case .idle:
            self.navigationEvents.send(.idle)

        case let .navigating(currentStepGeometryIndex,
                             snappedUserLocation,
                             remainingSteps,
                             remainingWaypoints,
                             progress,
                             deviation,
                             visualInstruction,
                             spokenInstruction,
                             annotationJson):

            switch deviation {
            case .noDeviation:
                break
            case let .offRoute(deviationFromRouteLine):
                self.navigationEvents.send(.devaited(RouteDeviation.offRoute(deviationFromRouteLine: deviationFromRouteLine)))
            }

            self.navigationEvents.send(.progressing(progress))

            if let visualInstruction {
                self.navigationEvents.send(.visualInstruction(visualInstruction))
            }

            if let spokenInstruction {
                self.navigationEvents.send(.spokenInstruction(spokenInstruction))
            }

            if let annotationJson {
                let annotation = self.parseAnnotation(json: annotationJson)
                self.navigationEvents.send(.currentPositionAnnotation(annotation))
            }

        case .complete:
            self.navigationEvents.send(.arrived)
        }
    }

    private func parseAnnotation(json: String) -> ValhallaOsrmAnnotation? {
        guard let data = json.data(using: .utf8) else {
            return nil
        }

        return try? JSONDecoder().decode(ValhallaOsrmAnnotation.self, from: data)
    }
}

// MARK: - FerrostarCoreDelegate

extension NavigationEngine: FerrostarCoreDelegate {
    func core(
        _: FerrostarCore,
        correctiveActionForDeviation _: Double,
        remainingWaypoints waypoints: [Waypoint]
    ) -> CorrectiveAction {
        return .getNewRoutes(waypoints: waypoints)
    }

    func core(_ core: FerrostarCore, loadedAlternateRoutes routes: [Route]) {
        if core.state?.isCalculatingNewRoute ?? false,
           let route = routes.first {
            do {
                // Most implementations will probably reuse existing configs (the default implementation does),
                // but we provide devs with flexibility here.
                let config = SwiftNavigationControllerConfig(
                    stepAdvance: .relativeLineStringDistance(
                        minimumHorizontalAccuracy: 32,
                        automaticAdvanceDistance: 10
                    ),
                    routeDeviationTracking: .staticThreshold(
                        minimumHorizontalAccuracy: 25,
                        maxAcceptableDeviation: 20
                    ), snappedLocationCourseFiltering: .snapToRoute
                )
                try core.startNavigation(
                    route: route,
                    config: config
                )
            } catch {
                // Users of the framework my develop their own responses here, such as notifying the user if appropriate
                Logger.routing.error("alternate routes error: \(error.localizedDescription)")
            }
        }
    }
}
