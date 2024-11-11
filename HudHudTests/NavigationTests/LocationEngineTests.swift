//
//  LocationEngineTests.swift
//  HudHud
//
//  Created by Ali Hilal on 06/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Combine
import CoreLocation
import FerrostarCore
import FerrostarCoreFFI
import MapLibre
import XCTest
@testable import HudHud

// MARK: - LocationEngineTests

final class LocationEngineTests: XCTestCase {

    // MARK: Properties

    var sut: LocationEngine!
    var cancellables: Set<AnyCancellable>!

    // MARK: Overridden Functions

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
        self.sut = LocationEngine()
        self.cancellables = []
        DebugStore().simulateRide = false
    }

    override func tearDown() {
        self.cancellables = nil
        self.sut = nil
        super.tearDown()
    }

    // MARK: Functions

    func test_initialState() {
        XCTAssertTrue(self.sut.locationProvider is CoreLocationProvider)
        XCTAssertEqual(self.sut.currentType, .standard)
        XCTAssertFalse(self.sut.isSimulatingLocation)
        XCTAssertEqual(self.sut.currentMode, .raw)
        XCTAssertNil(self.sut.lastLocation)
    }

    func test_switchMode_emitsCorrectEvent() {
        assertModeChange(to: .snapped)
    }

    func test_switchToSimulated_emitsProviderChangedEvent() {
        assertProviderChange(to: .simulated) {
            self.sut.switchToSimulated(route: .stub())
        }
    }

    func test_switchToStandard_fromSimulated() {
        self.sut.switchToSimulated(route: .stub())
        assertProviderChange(to: .standard) {
            self.sut.switchToStandard()
        }
    }

    func test_rawLocationUpdate_inRawMode() {
        let location = makeUserLocation()
        assertLocationUpdate(location: location, mode: .raw) { location in
            simulateRawLocationUpdate(location)
        }
    }

    func test_snappedLocationUpdate_inSnappedMode() {
        let location = makeUserLocation()
        assertLocationUpdate(location: location, mode: .snapped) { location in
            self.sut.update(withSnaplocation: location.clLocation)
        }
    }

    func test_rawLocationUpdates_updatePassthroughManager() {
        let location = makeUserLocation()
        let delegate = setupMockDelegate()

        assertPassthroughManagerUpdate(location: location, delegate: delegate) { location in
            simulateRawLocationUpdate(location)
        }
    }

    func test_snappedLocationUpdates_updatePassthroughManager() {
        self.sut.swithcMode(to: .snapped)
        let location = makeUserLocation()

        self.sut.update(withSnaplocation: location.clLocation)

        let passedLocation = self.sut.locationManager.lastLocation
        XCTAssertNotNil(passedLocation)
        XCTAssertEqual(passedLocation?.coordinate.latitude, location.coordinates.lat)
        XCTAssertEqual(passedLocation?.coordinate.longitude, location.coordinates.lng)
    }

    func test_rawLocationUpdate_ignoredInSnappedMode() {
        self.sut.swithcMode(to: .snapped)
        let location = makeUserLocation()

        assertNoLocationUpdate("No location update in snapped mode") {
            simulateRawLocationUpdate(location)
        }
    }

    func test_snappedLocationUpdate_ignoredInRawMode() {
        let location = makeUserLocation()

        assertNoLocationUpdate("No location update in raw mode") {
            self.sut.update(withSnaplocation: location.clLocation)
        }
    }

    func test_passThroughManager_delegateNotification() {
        let location = makeUserLocation()
        let delegate = setupMockDelegate()

        assertPassthroughManagerUpdate(location: location, delegate: delegate) { _ in
            simulateRawLocationUpdate(location)
        }
    }

    func test_passThroughManager_authorizationStatus() {
        // swiftlint:disable:next force_cast
        let provider = self.sut.locationProvider as! CoreLocationProvider
        let initialStatus = provider.authorizationStatus

        XCTAssertEqual(self.sut.locationManager.authorizationStatus, initialStatus)
    }

    func test_passThroughManager_startUpdating() {
        let delegate = setupMockDelegate()
        let expectation = expectation(description: "Location update received")
        delegate.didUpdateLocationsExpectation = expectation

        let lastLocation = makeUserLocation().clLocation
        self.sut.locationManager.updateLocation(lastLocation)
        self.sut.locationManager.startUpdatingLocation()

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(delegate.receivedLocations?.count, 1)
        XCTAssertEqual(delegate.receivedLocations?.first?.coordinate.latitude, lastLocation.coordinate.latitude)
    }

}

// MARK: - Private

private extension LocationEngineTests {

    func assertNoLocationUpdate(_ description: String,
                                timeout: TimeInterval = 0.5,
                                file _: StaticString = #file,
                                line _: UInt = #line,
                                perform action: () -> Void) {
        let expectation = expectation(description: description)
        expectation.isInverted = true

        self.sut.events.sink { event in
            if case .locationUpdated = event {
                expectation.fulfill()
            }
        }.store(in: &self.cancellables)

        action()

        wait(for: [expectation], timeout: timeout)
    }

    func assertModeChange(to expectedMode: LocationMode, file: StaticString = #file, line: UInt = #line) {
        self.assertPublishedEvent(description: "Mode changed event",
                                  expectedEventType: .modeChanged(expectedMode),
                                  file: file,
                                  line: line) {
            self.sut.swithcMode(to: expectedMode)
        }
        XCTAssertEqual(self.sut.currentMode, expectedMode, file: file, line: line)
    }

    func assertProviderChange(to expectedType: LocationProviderType, file: StaticString = #file, line: UInt = #line, action: () -> Void) {
        self.assertPublishedEvent(description: "Provider changed event", expectedEventType: .providerChanged(expectedType), file: file, line: line) {
            action()
        }
        XCTAssertEqual(self.sut.currentType, expectedType, file: file, line: line)
    }

    func assertLocationUpdate(location: UserLocation,
                              mode: LocationMode,
                              file: StaticString = #file,
                              line: UInt = #line,
                              perform update: (UserLocation) -> Void) {
        self.sut.swithcMode(to: mode)

        self.assertPublishedEvent(description: "Location update event",
                                  expectedEventType: .locationUpdated(location.clLocation),
                                  file: file,
                                  line: line) {
            update(location)
        }

        XCTAssertEqual(self.sut.lastLocation?.coordinate.latitude, location.coordinates.lat, file: file, line: line)
        XCTAssertEqual(self.sut.lastLocation?.coordinate.longitude, location.coordinates.lng, file: file, line: line)
    }

    func assertPassthroughManagerUpdate(location: UserLocation,
                                        delegate: MockMLNLocationManagerDelegate,
                                        file: StaticString = #file,
                                        line: UInt = #line,
                                        perform update: (UserLocation) -> Void) {
        let expectation = expectation(description: "Location update received")
        delegate.didUpdateLocationsExpectation = expectation

        update(location)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(delegate.receivedLocations?.first?.coordinate.latitude, location.coordinates.lat, file: file, line: line)
        XCTAssertEqual(delegate.receivedLocations?.first?.coordinate.longitude, location.coordinates.lng, file: file, line: line)
    }

    func assertPublishedEvent(description: String,
                              expectedEventType: LocationEngineEvent,
                              timeout: TimeInterval = 1.0,
                              file: StaticString = #file,
                              line: UInt = #line,
                              action: () -> Void) {
        let expectation = expectation(description: description)
        var receivedEvent: LocationEngineEvent?

        self.sut.events.sink { event in
            receivedEvent = event
            expectation.fulfill()
        }.store(in: &self.cancellables)

        action()

        wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(receivedEvent, expectedEventType, file: file, line: line)
    }

    func setupMockDelegate() -> MockMLNLocationManagerDelegate {
        let delegate = MockMLNLocationManagerDelegate()
        self.sut.locationManager.delegate = delegate
        return delegate
    }

    func simulateRawLocationUpdate(_ location: UserLocation) {
        if let provider = sut.locationProvider as? CoreLocationProvider {
            provider.locationManager(CLLocationManager(), didUpdateLocations: [location.clLocation])
        }
    }

    func makeUserLocation(lat: Double = 37.7749,
                          lng: Double = -122.4194,
                          accuracy: Double = 10.0,
                          course: Double = 90,
                          speed: Double = 15.0,
                          timestamp: Date = Date(timeIntervalSinceReferenceDate: 0)) -> UserLocation {
        return UserLocation(coordinates: GeographicCoordinate(lat: lat, lng: lng),
                            horizontalAccuracy: accuracy,
                            courseOverGround: CourseOverGround(degrees: UInt16(course), accuracy: 5),
                            timestamp: timestamp,
                            speed: Speed(value: speed, accuracy: 1.0))
    }
}

// MARK: - Helpers

extension Route {

    static func stub() -> Route {
        let start = GeographicCoordinate(lat: 37.7749, lng: -122.4194)
        let stop = GeographicCoordinate(lat: 37.7739, lng: -122.4312)
        let geometry = [start, stop]
        let bbox = BoundingBox(sw: stop, ne: start)
        let waypoints = [
            Waypoint(coordinate: start.clLocationCoordinate2D, kind: .via),
            Waypoint(coordinate: stop.clLocationCoordinate2D, kind: .via)
        ]

        return Route(geometry: geometry,
                     bbox: bbox,
                     distance: Measurement(value: 1, unit: UnitLength.kilometers).value,
                     waypoints: waypoints,
                     steps: [
                         RouteStep(geometry: geometry,
                                   distance: 1000.0,
                                   duration: 120.0,
                                   roadName: "Test Street",
                                   instruction: "Continue straight",
                                   visualInstructions: [],
                                   spokenInstructions: [],
                                   annotations: nil)
                     ])
    }
}

// MARK: - MockMLNLocationManagerDelegate

final class MockMLNLocationManagerDelegate: NSObject, MLNLocationManagerDelegate {

    // MARK: Properties

    var didUpdateLocationsExpectation: XCTestExpectation?
    var receivedLocations: [CLLocation]?

    private var hasFullfilledExpectation = false

    // MARK: Functions

    func locationManager(_: any MLNLocationManager, didUpdate _: CLHeading) {}

    func locationManagerShouldDisplayHeadingCalibration(_: any MLNLocationManager) -> Bool {
        false
    }

    func locationManager(_: any MLNLocationManager, didFailWithError _: any Error) {}

    func locationManagerDidChangeAuthorization(_: any MLNLocationManager) {}

    func locationManager(_: MLNLocationManager, didUpdate locations: [CLLocation]) {
        self.receivedLocations = locations
        if !self.hasFullfilledExpectation {
            self.didUpdateLocationsExpectation?.fulfill()
            self.hasFullfilledExpectation = true
        }
    }
}
