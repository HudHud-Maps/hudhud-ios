//
//  LocationEngine.swift
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

// MARK: - LocationEngine

@Observable
final class LocationEngine {

    // MARK: Properties

    private(set) var locationProvider: LocationProviding
    private(set) var locationManager: PassthroughLocationManager
    private(set) var currentMode: LocationMode = .raw
    private(set) var currentType: LocationProviderType

    private let eventsSubject = PassthroughSubject<LocationEngineEvent, Never>()
    private var cancellables = Set<AnyCancellable>()

    // MARK: Computed Properties

    var events: AnyPublisher<LocationEngineEvent, Never> {
        self.eventsSubject.eraseToAnyPublisher()
    }

    var lastLocation: CLLocation? {
        self.locationManager.lastLocation
    }

    var isSimulatingLocation: Bool {
        self.currentType == .simulated
    }

    // MARK: Lifecycle

    // MARK: -

    init(type: LocationProviderType = .standard) {
        self.currentType = type
        let provider = type.provider
        self.locationProvider = provider
        self.locationManager = PassthroughLocationManager(authorizationStatus: provider.authorizationStatus, headingOrientation: .portrait)
        self.setupSubscriptions()
    }

    // MARK: Functions

    // MARK: - Public Methods

    func switchToSimulated(route: Route) {
        guard self.currentType != .simulated else { return }
        let provider = SimulatedLocationProvider()
        self.updateProvider(.simulated, newProvider: provider)
        try? provider.setSimulatedRoute(route, bias: .left(5))
        provider.startUpdating()
    }

    func switchToStandard() {
        guard self.currentType != .standard else { return }
        let provider = CoreLocationProvider(activityType: .automotiveNavigation, allowBackgroundLocationUpdates: true)
        self.updateProvider(.standard, newProvider: provider)
        provider.startUpdating()
    }

    func swithcMode(to mode: LocationMode) {
        self.currentMode = mode
        self.eventsSubject.send(.modeChanged(mode))
    }

    func update(withSnaplocation location: CLLocation) {
        guard self.currentMode == .snapped else {
            print("Location mode is not set to .snapped, skipping location update")
            return
        }

        self.update(withLocation: location)
    }

    private func update(withLocation location: CLLocation) {
        self.locationManager.updateLocation(location)

        self.eventsSubject.send(.locationUpdated(location))
    }

    // MARK: - Private Methods

    private func updateProvider(_ type: LocationProviderType, newProvider: LocationProviding) {
        self.locationProvider.stopUpdating()

        self.currentType = type
        self.locationProvider = newProvider

        self.setupSubscriptions()
        self.eventsSubject.send(.providerChanged(type))
    }

    private func setupSubscriptions() {
        self.cancellables.removeAll()

        let publisher: Published<UserLocation?>.Publisher? = switch self.locationProvider {
        case let simulated as SimulatedLocationProvider:
            simulated.$lastLocation
        case let core as CoreLocationProvider:
            core.$lastLocation
        default:
            nil
        }

        publisher?
            .compactMap { $0?.clLocation }
            .receive(on: DispatchQueue.main)
            .filter { [weak self] _ in self?.currentMode == .raw }
            .sink { [weak self] location in
                self?.update(withLocation: location)
            }
            .store(in: &self.cancellables)
    }
}

private extension LocationProviderType {
    var provider: LocationProviding {
        switch self {
        case .standard: return CoreLocationProvider(activityType: .automotiveNavigation, allowBackgroundLocationUpdates: true)
        case .simulated: return SimulatedLocationProvider()
        }
    }
}
