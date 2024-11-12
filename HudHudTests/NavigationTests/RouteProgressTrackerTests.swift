//
//  RouteProgressTrackerTests.swift
//  HudHudTests
//
//  Created by Ali Hilal on 12/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import XCTest
@testable import HudHud

final class RouteProgressTrackerTests: XCTestCase {

    // MARK: Properties

    private var tracker: RouteProgressTracker!
    private let accuracy = 0.00001

    private let sampleCoordinates: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 25.0, longitude: 55.0),
        CLLocationCoordinate2D(latitude: 25.1, longitude: 55.2),
        CLLocationCoordinate2D(latitude: 25.2, longitude: 55.4),
        CLLocationCoordinate2D(latitude: 25.3, longitude: 55.6)
    ]

    private let sampleDistance: CLLocationDistance = 1000

    // MARK: Overridden Functions

    override func setUp() {
        super.setUp()
        self.tracker = RouteProgressTracker()
    }

    override func tearDown() {
        self.tracker = nil
        super.tearDown()
    }

    // MARK: Functions

    func testInitializationWithEmptyCoordinates() {
        let tracker = RouteProgressTracker()

        let progress = tracker.calcualteProgress(from: CLLocation(latitude: 25.0, longitude: 55.0),
                                                 and: 0)

        XCTAssertEqual(progress.totalDistance, 0)
        XCTAssertEqual(progress.drivenDistance, 0)
        XCTAssertTrue(progress.drivenCoordinates.isEmpty)
        XCTAssertTrue(progress.remainingCoordinates.isEmpty)
    }

    func testInitializationWithCoordinates() {
        let tracker = RouteProgressTracker(coordinates: sampleCoordinates,
                                           totalDistance: sampleDistance)

        let progress = tracker.calcualteProgress(from: CLLocation(latitude: self.sampleCoordinates[0].latitude,
                                                                  longitude: self.sampleCoordinates[0].longitude),
                                                 and: 0)

        XCTAssertEqual(progress.totalDistance, self.sampleDistance)
        XCTAssertFalse(progress.drivenCoordinates.isEmpty)
        XCTAssertFalse(progress.remainingCoordinates.isEmpty)
    }

    func testUpdateWithNewRoute() {
        self.tracker = RouteProgressTracker()

        self.tracker.update(coordinates: self.sampleCoordinates, totalDistance: self.sampleDistance)

        let progress = self.tracker.calcualteProgress(from: CLLocation(latitude: self.sampleCoordinates[0].latitude,
                                                                       longitude: self.sampleCoordinates[0].longitude),
                                                      and: 0)

        XCTAssertEqual(progress.totalDistance, self.sampleDistance)
        XCTAssertEqual(progress.remainingCoordinates.count, self.sampleCoordinates.count)
    }

    func testProgressAtStart() {
        self.tracker.update(coordinates: self.sampleCoordinates, totalDistance: self.sampleDistance)

        let progress = self.tracker.calcualteProgress(from: CLLocation(latitude: self.sampleCoordinates[0].latitude,
                                                                       longitude: self.sampleCoordinates[0].longitude),
                                                      and: 0)

        XCTAssertEqual(progress.totalDistance, self.sampleDistance)
        XCTAssertEqual(progress.drivenDistance, 0)
        XCTAssertLessThanOrEqual(progress.drivenCoordinates.count, 3) // start point + interpolated points
        XCTAssertEqual(progress.remainingCoordinates.count, self.sampleCoordinates.count)
    }

    func testProgressAtMiddle() {
        self.tracker.update(coordinates: self.sampleCoordinates, totalDistance: self.sampleDistance)

        let middlePoint = self.sampleCoordinates[1]
        let progress = self.tracker.calcualteProgress(from: CLLocation(latitude: middlePoint.latitude,
                                                                       longitude: middlePoint.longitude),
                                                      and: self.sampleDistance / 2)

        XCTAssertEqual(progress.totalDistance, self.sampleDistance)
        XCTAssertEqual(progress.drivenDistance, self.sampleDistance / 2)
        XCTAssertFalse(progress.drivenCoordinates.isEmpty)
        XCTAssertFalse(progress.remainingCoordinates.isEmpty)
    }

    func testProgressAtEnd() throws {
        self.tracker.update(coordinates: self.sampleCoordinates, totalDistance: self.sampleDistance)

        let endPoint = try XCTUnwrap(sampleCoordinates.last)
        let progress = self.tracker.calcualteProgress(from: CLLocation(latitude: endPoint.latitude,
                                                                       longitude: endPoint.longitude),
                                                      and: self.sampleDistance)

        XCTAssertEqual(progress.totalDistance, self.sampleDistance)
        XCTAssertEqual(progress.drivenDistance, self.sampleDistance)
        XCTAssertGreaterThan(progress.drivenCoordinates.count, 0)
        XCTAssertLessThanOrEqual(progress.remainingCoordinates.count, 1)
    }

    func testProgressWithOffRouteLocation() {
        self.tracker.update(coordinates: self.sampleCoordinates, totalDistance: self.sampleDistance)

        let offRouteLocation = CLLocation(latitude: 26.0, longitude: 56.0)
        let progress = self.tracker.calcualteProgress(from: offRouteLocation,
                                                      and: self.sampleDistance / 2)

        XCTAssertEqual(progress.totalDistance, self.sampleDistance)
        XCTAssertNotNil(progress.lastPosition)
        XCTAssertFalse(progress.drivenCoordinates.isEmpty)
        XCTAssertFalse(progress.remainingCoordinates.isEmpty)
    }

    func testFlush() {
        self.tracker.update(coordinates: self.sampleCoordinates, totalDistance: self.sampleDistance)
        let initialProgress = self.tracker.calcualteProgress(from: CLLocation(latitude: self.sampleCoordinates[0].latitude,
                                                                              longitude: self.sampleCoordinates[0].longitude),
                                                             and: 0)

        XCTAssertEqual(initialProgress.totalDistance, self.sampleDistance)
        XCTAssertFalse(initialProgress.drivenCoordinates.isEmpty)

        self.tracker.flush()

        let progress = self.tracker.calcualteProgress(from: CLLocation(latitude: 25.0, longitude: 55.0),
                                                      and: 0)

        XCTAssertEqual(progress.totalDistance, 0)
        XCTAssertEqual(progress.drivenDistance, 0)
        XCTAssertTrue(progress.drivenCoordinates.isEmpty)
        XCTAssertTrue(progress.remainingCoordinates.isEmpty)
        XCTAssertEqual(progress.lastPosition.distanceFromStart, 0)
        XCTAssertEqual(progress.lastPosition.distanceFromSegmentStart, 0)
    }

    func testPerformanceWithLargeRoute() {
        _ = XCTSkip("No need to run on CI, only for local testing")
        let cityRoute = (0 ..< 250).map { i in
            CLLocationCoordinate2D(latitude: 25.0 + Double(i) * 0.001,
                                   longitude: 55.0 + Double(i) * 0.001)
        }

        // Long route ~1000km: ~2500 points (based on real data)
        let longRoute = (0 ..< 2408).map { i in
            CLLocationCoordinate2D(latitude: 25.0 + Double(i) * 0.001,
                                   longitude: 55.0 + Double(i) * 0.001)
        }

        let options = XCTMeasureOptions()
        options.iterationCount = 5

        measure(options: options) {
            self.tracker.update(coordinates: cityRoute, totalDistance: 30000)
            _ = self.tracker.calcualteProgress(from: CLLocation(latitude: 25.15, longitude: 55.15),
                                               and: 15000)

            self.tracker.update(coordinates: longRoute, totalDistance: 1_000_000)
            _ = self.tracker.calcualteProgress(from: CLLocation(latitude: 25.5, longitude: 55.5),
                                               and: 500_000)
        }
    }
}
