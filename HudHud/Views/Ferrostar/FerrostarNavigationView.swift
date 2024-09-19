//
//  FerrostarNavigationView.swift
//  HudHud
//
//  Created by patrick on 04.09.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import FerrostarCore
import FerrostarCoreFFI
import FerrostarMapLibreUI
import FerrostarSwiftUI
import Foundation
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import SwiftUI

// MARK: - FerrostarNavigationView

struct FerrostarNavigationView: View {

    // MARK: Static Properties

    static let initialLocation = CLLocation(
        latitude: 24.688028,
        longitude: 46.689256
    )

    // MARK: Properties

    let styleURL = URL(
        string:
        "https://static.maptoolkit.net/styles/hudhud/hudhud-default-v1.json?api_key=hudhud"
    )! // swiftlint:disable:this force_unwrapping

    let waypoints: [CLLocation]

    private let navigationDelegate = NavigationDelegate()

    @Environment(\.dismiss) private var dismiss

    // NOTE: This is probably not ideal but works for demo purposes.
    // This causes a thread performance checker warning log.
    private let spokenInstructionObserver = AVSpeechSpokenInstructionObserver(
        isMuted: false)

    private var locationProvider: LocationProviding
    @ObservedObject private var ferrostarCore: FerrostarCore

    @State private var isFetchingRoutes = true
    @State private var routes: [Route]?
    @State private var camera: MapViewCamera = .center(
        initialLocation.coordinate, zoom: 16
    )
    @State private var snappedCamera = true

    // MARK: Computed Properties

    var locationLabel: String {
        guard let userLocation = locationProvider.lastLocation else {
            return
                "No location - authed as \(self.locationProvider.authorizationStatus)"
        }

        return "±\(Int(userLocation.horizontalAccuracy))m accuracy"
    }

    @State private var errorMessage: String? {
        didSet {
            Task {
                try await Task.sleep(nanoseconds: 8 * NSEC_PER_SEC)
                self.errorMessage = nil
            }
        }
    }

    // MARK: Lifecycle

    init(waypoints: [CLLocation]) {
        let shouldWeSimulate = DebugStore().simulateRide
        if shouldWeSimulate {
            let simulated = SimulatedLocationProvider(
                location: FerrostarNavigationView.initialLocation)
            simulated.warpFactor = 4
            self.locationProvider = simulated
        } else {
            self.locationProvider = CoreLocationProvider(
                activityType: .automotiveNavigation,
                allowBackgroundLocationUpdates: true
            )
        }

        // Configure the navigation session.
        // You have a lot of flexibility here based on your use case.
        let config = SwiftNavigationControllerConfig(
            stepAdvance: .relativeLineStringDistance(
                minimumHorizontalAccuracy: 32, automaticAdvanceDistance: 10
            ),
            routeDeviationTracking: .staticThreshold(
                minimumHorizontalAccuracy: 25, maxAcceptableDeviation: 20
            ), snappedLocationCourseFiltering: .snapToRoute
        )

        self.ferrostarCore = FerrostarCore(
            customRouteProvider: HudHudGraphHopperRouteProvider(),
            locationProvider: self.locationProvider,
            navigationControllerConfig: config
        )

        self.waypoints = waypoints

        self.ferrostarCore.delegate = self.navigationDelegate

        // Initialize text-to-speech; note that this is NOT automatic.
        // You must set a spokenInstructionObserver.
        // Fortunately, this is pretty easy with the provided class
        // backed by AVSpeechSynthesizer.
        // You can customize the instance it further as needed,
        // or replace with your own.
        self.ferrostarCore.spokenInstructionObserver = self.spokenInstructionObserver
    }

    // MARK: Content

    var body: some View {
        NavigationStack {
            DynamicallyOrientingNavigationView(
                styleURL: self.styleURL,
                camera: self.$camera,
                navigationState: self.ferrostarCore.state,
                onTapExit: {
                    self.stopNavigation()
                    self.dismiss()
                }
            )
            .innerGrid(
                topCenter: {
                    if let errorMessage {
                        NavigationUIBanner(severity: .error) {
                            Text(errorMessage)
                        }
                        .onTapGesture {
                            self.errorMessage = nil
                        }
                    } else if self.isFetchingRoutes {
                        NavigationUIBanner(severity: .loading) {
                            Text("Loading route...")
                        }
                    }
                },
                bottomTrailing: {
                    VStack {
                        Text(self.locationLabel)
                            .font(.caption)
                            .padding(.all, 8)
                            .foregroundColor(.white)
                            .background(
                                Color.black.opacity(0.7).clipShape(
                                    .buttonBorder, style: FillStyle()
                                ))

                        if case .navigating = self.ferrostarCore.state?.tripState {
                        } else {
                            NavigationUIButton {
                                self.dismiss()
                            } label: {
                                Text("End")
                                    .font(.body.bold())
                            }
                            .disabled(self.routes?.isEmpty == true)
                            .shadow(radius: 10)
                        }
                    }
                }
            )
            .onAppear {
                self.camera = .trackUserLocationWithCourse(zoom: 16, pitch: 0.5)
                Task {
                    await self.getRouteAndStartNavigation()
                }
            }
        }
    }

    // MARK: Functions

    func getRoutes() async throws {
        guard let userLocation = locationProvider.lastLocation else {
            throw NavigationError.userLocationNotFound
        }

        let waypoints = waypoints.map {
            Waypoint(
                coordinate: GeographicCoordinate(
                    lat: $0.coordinate.latitude, lng: $0.coordinate.longitude
                ),
                kind: .break
            )
        }
        self.routes = try await self.ferrostarCore.getRoutes(
            initialLocation: userLocation,
            waypoints: waypoints
        )

        self.isFetchingRoutes = false
        print("DemoApp: successfully fetched a route")

        if let simulated = locationProvider as? SimulatedLocationProvider,
           let route = routes?.first, let firstGeometry = route.geometry.first {
            // This configures the simulator to the desired route.
            // The ferrostarCore.startNavigation will still start the location
            // provider/simulator.
            simulated
                .lastLocation = UserLocation(
                    clCoordinateLocation2D: firstGeometry.clLocationCoordinate2D
                )
            print("DemoApp: setting initial location")
        }
    }

    func startNavigation() async throws {
        guard let route = routes?.first else {
            throw NavigationError.noRouteAvailable
        }

        if let simulated = locationProvider as? SimulatedLocationProvider {
            // This configures the simulator to the desired route.
            // The ferrostarCore.startNavigation will still start the location
            // provider/simulator.
            try simulated.setSimulatedRoute(route, resampleDistance: 5)
            print("DemoApp: setting route to be simulated")
        }

        // Starts the navigation state machine.
        // It's worth having a look through the parameters,
        // as most of the configuration happens here.
        try self.ferrostarCore.startNavigation(route: route)

        self.preventAutoLock()
    }

    func getRouteAndStartNavigation() async {
        do {
            try await self.getRoutes()
            try await self.startNavigation()
        } catch {
            print(
                "DemoApp: Error getting routes or starting navigation: \(error)"
            )
            self.errorMessage = error.localizedDescription
        }
    }

    func stopNavigation() {
        self.ferrostarCore.stopNavigation()
        self.camera = .center(
            FerrostarNavigationView.initialLocation.coordinate, zoom: 14
        )
        self.allowAutoLock()
    }

    private func preventAutoLock() {
        UIApplication.shared.isIdleTimerDisabled = true
    }

    private func allowAutoLock() {
        UIApplication.shared.isIdleTimerDisabled = false
    }
}

// MARK: - NavigationError

enum NavigationError: LocalizedError {
    case userLocationNotFound
    case noRouteAvailable

    // MARK: Computed Properties

    var errorDescription: String? {
        switch self {
        case .userLocationNotFound:
            return NSLocalizedString(
                "User location could not be found.", comment: ""
            )
        case .noRouteAvailable:
            return NSLocalizedString(
                "No route is available for the destination.", comment: ""
            )
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .userLocationNotFound:
            return NSLocalizedString(
                "Please ensure location services are enabled and try again.",
                comment: ""
            )
        case .noRouteAvailable:
            return NSLocalizedString(
                "Try a different destination or check for connectivity issues.",
                comment: ""
            )
        }
    }
}

#Preview {
    FerrostarNavigationView(waypoints: [
        CLLocation(latitude: 24.949783, longitude: 46.700929)
    ])
}
