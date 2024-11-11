//
//  HudHudUITests.swift
//  HudHudUITests
//
//  Created by Patrick Kladek on 29.01.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import XCTest

// MARK: - HudHudUITests

final class HudHudUITests: XCTestCase {

    // MARK: Overridden Functions

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        self.continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp
        // method is a good place to do this.
        XCUIDevice.shared.location = XCUILocation(location: .theGarage)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: Functions

    func testForSearchField() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.start()

        app.textFields["Search"].waitForExists()
    }
}

extension XCUIApplication {

    static var springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    func start() {
        self.resetAuthorizationStatus(for: .location)
        self.launch()

        XCUIApplication.springboard.alerts[contains: "Hudhud"].waitForExists()
        XCUIApplication.springboard.alerts[contains: "Hudhud"].buttons.element(boundBy: 1).tap()
    }
}

extension CLLocation {

    static func coordinate(_ coordinate: CLLocationCoordinate2D, altitude: CLLocationDistance = 0) -> CLLocation {
        return CLLocation(coordinate: coordinate, altitude: altitude, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: .now)
    }

    static let theGarage: CLLocation = .coordinate(.theGarage, altitude: 647)
}

extension CLLocationCoordinate2D {

    static let theGarage = CLLocationCoordinate2D(latitude: 24.7193306, longitude: 46.6468)
}
