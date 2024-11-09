//
//  HorizonEngineTests.swift
//  HudHudTests
//
//  Created by Ali Hilal on 05/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Combine
import CoreLocation
import FerrostarCoreFFI
import Foundation
@testable import HudHud
import XCTest

// MARK: - EventRecorder

private final class EventRecorder {

    // MARK: Nested Types

    enum EventType {
        case approachingSpeedCamera
        case passedSpeedCamera
        case approachingTrafficIncident
        case passedTrafficIncident
    }

    // MARK: Properties

    var recordedEvents: [HorizionEvent] = []
    var cancellables = Set<AnyCancellable>()

    // MARK: Functions

    func hasEvent(ofType eventType: EventType) -> Bool {
        self.recordedEvents.contains { event in
            switch (event, eventType) {
            case (.approachingSpeedCamera, .approachingSpeedCamera): return true
            case (.passedSpeedCamera, .passedSpeedCamera): return true
            case (.approachingTrafficIncident, .approachingTrafficIncident): return true
            case (.passedTrafficIncident, .passedTrafficIncident): return true
            default: return false
            }
        }
    }
}

// MARK: - HorizonEngineTests

final class HorizonEngineTests: XCTestCase {

    // MARK: Properties

    private var engine: HorizonEngine!
    private var testRoute: Route!
    private var eventRecorder: EventRecorder!

    // MARK: Overridden Functions

    override func setUp() {
        super.setUp()
        self.setupTestEnvironment()
    }

    override func tearDown() {
        self.engine = nil
        self.testRoute = nil
        self.eventRecorder = nil
        super.tearDown()
    }

    // MARK: Functions

    // MARK: - Basic Tests

    func testEngineInitialization() {
        XCTAssertNotNil(self.engine)
    }

    func testStartMonitoring() async {
        self.engine.startMonitoring(route: self.testRoute)

        let camera = self.testRoute.speedCameras.first!

        let approachLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: camera.location.latitude - 0.005, // roughly 500m south
                longitude: camera.location.longitude
            ),
            altitude: 0,
            horizontalAccuracy: 10,
            verticalAccuracy: 10,
            course: Direction.north.rawValue, // towards the camera
            speed: 20,
            timestamp: Date()
        )

        self.engine.processLocation(approachLocation)
        try? await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertFalse(self.eventRecorder.recordedEvents.isEmpty, "Should have generated events")

        let approachingEvent = self.eventRecorder.recordedEvents.first { event in
            if case let .approachingSpeedCamera(camera, distance) = event {
                XCTAssertEqual(camera.id, "test-camera")
                XCTAssertEqual(camera.type, .fixed)
                XCTAssertEqual(camera.direction, .forward)
                XCTAssertLessThan(distance.value, 2000, "Distance should be within scan range")
                return true
            }
            return false
        }

        XCTAssertNotNil(approachingEvent, "Should have generated an approaching speed camera event")
    }

    func testStopMonitoring() {
        self.engine.startMonitoring(route: self.testRoute)
        self.engine.stopMonitoring()

        let location = CLLocation(latitude: 0, longitude: 0)
        self.engine.processLocation(location)

        XCTAssertTrue(self.eventRecorder.recordedEvents.isEmpty)
    }

    // MARK: - Feature Detection Tests

    func testTrafficIncidentDetection() async {
        self.engine.startMonitoring(route: self.testRoute)

        let incidentLocation = self.testRoute.incidents.first!.location
        let locations = generateApproachLocations(to: incidentLocation)

        await processLocationsSequentially(locations)

        XCTAssertTrue(self.eventRecorder.hasEvent(ofType: .approachingTrafficIncident))
        XCTAssertTrue(self.eventRecorder.hasEvent(ofType: .passedTrafficIncident))
    }

    func testMultipleFeatureDetection() async {
        self.engine.startMonitoring(route: self.testRoute)

        let camera = self.testRoute.speedCameras.first!
        let incident = self.testRoute.incidents.first!

        // to find position on route before both features
        let routeIndex = min(
            self.testRoute.geometry.firstIndex { coord in
                coord.lat == camera.location.latitude && coord.lng == camera.location.longitude
            } ?? 0,
            self.testRoute.geometry.firstIndex { coord in
                coord.lat == incident.location.latitude && coord.lng == incident.location.longitude
            } ?? 0
        )

        let testLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: self.testRoute.geometry[max(0, routeIndex - 2)].lat,
                longitude: self.testRoute.geometry[max(0, routeIndex - 2)].lng
            ),
            altitude: 0,
            horizontalAccuracy: 10,
            verticalAccuracy: 10,
            course: Direction.north.rawValue,
            speed: 20,
            timestamp: Date()
        )

        self.engine.processLocation(testLocation)
        try? await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertGreaterThanOrEqual(
            self.eventRecorder.recordedEvents.count,
            2,
            "Should detect multiple features (camera and incident). Got events: \(self.eventRecorder.recordedEvents)"
        )

        XCTAssertTrue(
            self.eventRecorder.hasEvent(ofType: .approachingSpeedCamera),
            "Should have detected speed camera"
        )
        XCTAssertTrue(
            self.eventRecorder.hasEvent(ofType: .approachingTrafficIncident),
            "Should have detected traffic incident"
        )
    }

    func testDistanceBasedAlerts() {
        self.engine.startMonitoring(route: self.testRoute)

        let locations = [
            (distance: 2000.0, shouldAlert: false),
            (distance: 1500.0, shouldAlert: false),
            (distance: 900.0, shouldAlert: true),
            (distance: 500.0, shouldAlert: false),
            (distance: 100.0, shouldAlert: false),
            (distance: 0.0, shouldAlert: false)
        ]

        for (index, test) in locations.enumerated() {
            let location = CLLocation(
                coordinate: calculateCoordinate(atDistance: test.distance),
                altitude: 0,
                horizontalAccuracy: 10,
                verticalAccuracy: 10,
                course: 0,
                speed: 20,
                timestamp: Date().addingTimeInterval(Double(index))
            )

            self.eventRecorder.recordedEvents.removeAll()
            self.engine.processLocation(location)

            let expectation = XCTestExpectation(description: "Process location")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("Events received after processing: \(self.eventRecorder.recordedEvents)")
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 1.0)

            let hasAlert = self.eventRecorder.recordedEvents.contains { event in
                if case .approachingSpeedCamera = event { return true }
                return false
            }
            print("Alert detected: \(hasAlert) (Expected: \(test.shouldAlert))")
        }
    }

    func testDistanceUpdateThreshold() async {
        self.engine.startMonitoring(route: self.testRoute)

        let testLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: 25.202045,
                longitude: 55.277876
            ),
            altitude: 0,
            horizontalAccuracy: 10,
            verticalAccuracy: 10,
            course: 0,
            speed: 20,
            timestamp: Date()
        )

        self.engine.processLocation(testLocation)
        try? await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertTrue(
            self.eventRecorder.hasEvent(ofType: .approachingSpeedCamera),
            "Failed to get initial speed camera event"
        )

        self.eventRecorder.recordedEvents.removeAll()

        let locations = stride(from: 900.0, through: 775.0, by: -25.0).map { distance in
            CLLocation(
                coordinate: calculateCoordinate(atDistance: distance),
                altitude: 0,
                horizontalAccuracy: 10,
                verticalAccuracy: 10,
                course: 0,
                speed: 20,
                timestamp: Date()
            )
        }

        await processLocationsSequentially(locations)

        let updates = self.eventRecorder.recordedEvents.filter { event in
            if case .approachingSpeedCamera = event { return true }
            return false
        }

        guard !updates.isEmpty else {
            XCTFail("No speed camera events were generated")
            return
        }

        let distances = updates.compactMap { event -> Double? in
            if case let .approachingSpeedCamera(_, distance) = event {
                return distance.value
            }
            return nil
        }

        guard distances.count > 1 else {
            XCTFail("Expected multiple distance updates, got \(distances.count)")
            return
        }

        for i in 1 ..< distances.count {
            let change = abs(distances[i] - distances[i - 1])
            XCTAssertGreaterThan(
                change,
                LocationConstants.significantDistanceChange,
                "Each update should represent a significant distance change"
            )
        }
    }

    // MARK: - Helper Setup Methods

    private func setupTestEnvironment() {
        let config = NavigationConfig(
            routeProvider: GraphHopperRouteProvider(),
            locationEngine: LocationEngine(),
            stepAdvanceConfig: .default,
            deviationConfig: .default,
            courseFiltering: .snapToRoute,
            horizonScanRange: .init(value: 2, unit: .kilometers),
            horizonUpdateInterval: 10,
            featureAlertConfig: .default
        )

        self.engine = HorizonEngine(configuration: config)
        self.testRoute = createTestRoute()
        self.eventRecorder = EventRecorder()

        self.engine.events
            .sink { [weak eventRecorder] event in
                eventRecorder?.recordedEvents.append(event)
            }
            .store(in: &self.eventRecorder.cancellables)
    }
}

extension HorizonEngineTests {

    private func isMonotonicallyDecreasing(_ array: [Double]) -> Bool {
        guard array.count > 1 else { return true }
        return zip(array, array.dropFirst()).allSatisfy(>)
    }

    private func generateDistanceTestLocations(
        from start: Double,
        to end: Double,
        step: Double
    ) -> [CLLocation] {
        stride(from: start, through: end, by: step).map { distance in
            let coordinate = self.calculateCoordinate(atDistance: distance)
            let course = coordinate.bearing(to: self.testRoute.geometry.last!.clLocationCoordinate2D)
            return CLLocation(
                coordinate: coordinate,
                altitude: 0,
                horizontalAccuracy: 10,
                verticalAccuracy: 10,
                course: course,
                speed: 20,
                timestamp: Date()
            )
        }
    }

    private func calculateCoordinate(atDistance meters: Double) -> CLLocationCoordinate2D {
        let camera = self.testRoute.speedCameras.first!.location
        let bearing = 180.0 // approaching the forward-facing camera
        let earthRadius = 6_371_000.0

        let lat1 = camera.latitude * .pi / 180
        let lon1 = camera.longitude * .pi / 180
        let angularDistance = meters / earthRadius

        let lat2 = asin(sin(lat1) * cos(angularDistance) +
            cos(lat1) * sin(angularDistance) * cos(bearing * .pi / 180))
        let lon2 = lon1 + atan2(sin(bearing * .pi / 180) * sin(angularDistance) * cos(lat1),
                                cos(angularDistance) - sin(lat1) * sin(lat2))

        return CLLocationCoordinate2D(
            latitude: lat2 * 180 / .pi,
            longitude: lon2 * 180 / .pi
        )
    }

    private func generateApproachLocations(to target: CLLocationCoordinate2D) -> [CLLocation] {
        let startLat = target.latitude - 0.01
        let startLon = target.longitude - 0.01
        let endLat = target.latitude + 0.01
        let endLon = target.longitude + 0.01

        let steps = 20

        return (0 ... steps).map { step in
            let progress = Double(step) / Double(steps)
            let lat = startLat + (endLat - startLat) * progress
            let lng = startLon + (endLon - startLon) * progress

            let bearing = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                .bearing(to: target)

            return CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                altitude: 0,
                horizontalAccuracy: 10,
                verticalAccuracy: 10,
                course: bearing,
                speed: 20,
                timestamp: Date().addingTimeInterval(Double(step) * 0.1)
            )
        }
    }

    private func processLocationsSequentially(_ locations: [CLLocation]) async {
        for location in locations {
            self.engine.processLocation(location)
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        try? await Task.sleep(nanoseconds: 500_000_000)
    }

    private func createTestRoute() -> Route {
        let coordinates: [CLLocationCoordinate2D] = [
            CLLocationCoordinate2D(latitude: 25.195197, longitude: 55.274376),
            CLLocationCoordinate2D(latitude: 25.196245, longitude: 55.274376),
            CLLocationCoordinate2D(latitude: 25.197312, longitude: 55.274376),
            CLLocationCoordinate2D(latitude: 25.198156, longitude: 55.274376),
            CLLocationCoordinate2D(latitude: 25.199234, longitude: 55.274376),
            CLLocationCoordinate2D(latitude: 25.200187, longitude: 55.274376),
            CLLocationCoordinate2D(latitude: 25.201045, longitude: 55.274376),
            CLLocationCoordinate2D(latitude: 25.202123, longitude: 55.274376),

            CLLocationCoordinate2D(latitude: 25.203234, longitude: 55.274376),

            CLLocationCoordinate2D(latitude: 25.204123, longitude: 55.274376),
            CLLocationCoordinate2D(latitude: 25.205234, longitude: 55.274376),
            CLLocationCoordinate2D(latitude: 25.206123, longitude: 55.274376),
            CLLocationCoordinate2D(latitude: 25.207234, longitude: 55.274376),
            CLLocationCoordinate2D(latitude: 25.208123, longitude: 55.274376),
            CLLocationCoordinate2D(latitude: 25.209234, longitude: 55.274376)
        ]

        let route = Route(
            geometry: coordinates.map { GeographicCoordinate(lat: $0.latitude, lng: $0.longitude) },
            bbox: BoundingBox(
                sw: .init(lat: coordinates.map(\.latitude).min()!, lng: coordinates.map(\.longitude).min()!),
                ne: .init(lat: coordinates.map(\.latitude).max()!, lng: coordinates.map(\.longitude).max()!)
            ),
            distance: 2000,
            waypoints: [],
            steps: []
        )

        Route.mockIncidents = [
            TrafficIncident(
                id: "test-incident",
                type: .accident,
                severity: .major,
                location: coordinates[10],
                description: "Test incident",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                length: .init(value: 500, unit: .meters),
                delayInSeconds: 300
            )
        ]

        Route.mockSpeedCameras = [
            SpeedCamera(
                id: "test-camera",
                speedLimit: .init(value: 80, unit: .kilometersPerHour),
                type: .fixed,
                direction: .forward,
                captureRange: .init(value: 100, unit: .meters),
                location: coordinates[8]
            )
        ]

        return route
    }
}
