//
//  CalculateTests.swift
//  HudHudTests
//
//  Created by Alaa . on 18/04/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

@testable import BackendService
@testable import FerrostarCoreFFI
@testable import HudHud
@testable import MapLibre
import XCTest

final class CalculateTests: XCTestCase {

    func testCalculateValidCoordinatesReturnsRouteWithSteps() async throws {
        let hudhudGraphhopper = GraphHopperRouteProvider()

        // When
        let startCoordinate = CLLocationCoordinate2D(latitude: 24.6875, longitude: 46.6845) //  Alfaisaliah Tower, Riyadh
        let endCoordinate = CLLocationCoordinate2D(latitude: 24.7311, longitude: 46.6701) // Kingdom Tower, Riyadh

        // Create route options with valid waypoints
        let waypoints = [Waypoint(coordinate: startCoordinate), Waypoint(coordinate: endCoordinate)]

        // Perform route calculation
        let routes = try await hudhudGraphhopper.getRoutes(waypoints: waypoints)

        // Then
        XCTAssertGreaterThan(routes.count, 0)
        XCTAssertGreaterThan(routes[0].steps.count, 0)
    }

    /*
     These two function commented for now cause they trigger an error that will be fixed later:
     In this particular case we expect an error returned from the backend as its an impossible route (Brazil to Riyadh, no road as there is an ocean in between) Point 1 is too far from Point 0 . Instead we are getting: "Point 0 is out of bounds: -8.2862722,-38.0328413, the bounds are: 33.9470146,59.8364067,16.1558757,33.4669626,-45.70500183105469,2981.10107421875" .

     https://linear.app/hudhudapp/issue/HUD-81/fix-routing-issue
     */
//    func testCalculateWithInvalidStartCoordinateThrowsInvalidInputError() async throws {
//        // Given
//        let routingService = RoutingService()
//
//        // When
//        let startCoordinate = CLLocationCoordinate2D(latitude: 1000.0, longitude: 2000.0) // Invalid start coordinate
//        let endCoordinate = CLLocationCoordinate2D(latitude: 24.7311, longitude: 46.6701) // Valid end coordinate(Kingdom Tower, Riyadh)
//
//        let waypoints = [Waypoint(coordinate: startCoordinate), Waypoint(coordinate: endCoordinate)]
//        let options = RouteOptions(waypoints: waypoints)
//
//        // Then
//        do {
//            let result = try await routingService.calculate(host: "gh.map.dev.hudhud.sa", options: options)
//            XCTFail("Expected an error but received a result: \(result)") // Fail the test if no error is thrown
//        } catch let error as RoutingService.ToursprungError {
//            // Assert that the correct error is thrown with the expected message
//            let expectedErrorMessage = "Point 0 is out of bounds: 1000.0,2000.0, the bounds are: -180.0,180.0,-85.0511284,82.5254024,-4100.47900390625,8775.1728515625"
//            XCTAssertEqual(error, RoutingService.ToursprungError.invalidInput(message: expectedErrorMessage))
//        } catch {
//            XCTFail("Unexpected error: \(error)")
//        }
//    }

//    func testCalculateImpossibleRouteThrowsNoRouteError() async throws {
//        // Given
//        let routingService = RoutingService()
//
//        // When
//        // Define coordinates that result in an impossible route (across a large body of water)
//        let startCoordinate = CLLocationCoordinate2D(latitude: -8.2862722, longitude: -38.0328413) // Brazil, Serra Talhada
//        let endCoordinate = CLLocationCoordinate2D(latitude: 24.7194294, longitude: 46.6463473) // Saudi, Riyadh, The Garage (Work)
//
//        let waypoints = [Waypoint(coordinate: startCoordinate), Waypoint(coordinate: endCoordinate)]
//        let options = RouteOptions(waypoints: waypoints)
//
//        // Then
//        do {
//            let result = try await routingService.calculate(host: "gh.map.dev.hudhud.sa", options: options)
//            XCTFail("Expected an error but received a result: \(result)")
//        } catch let error as RoutingService.ToursprungError {
//            if case let .invalidInput(message) = error {
//                XCTAssertEqual(message, "Point 1 is too far from Point 0: 24.7194294,46.6463473", "Invalid input message mismatch")
//            } else {
//                XCTFail("Unexpected error type: \(error)")
//            }
//        } catch {
//            XCTFail("Unexpected error occurred: \(error)")
//        }
//    }

}
