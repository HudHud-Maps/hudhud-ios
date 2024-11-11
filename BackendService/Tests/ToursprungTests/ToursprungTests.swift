//
//  ToursprungTests.swift
//  POIService
//
//  Created by Patrick Kladek on 10.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import XCTest
@testable import BackendService

final class ToursprungTests: XCTestCase {

    func testGeocoder() async throws {
        let geocoder = Geocoder(session: .shared)

        let pois = try await geocoder.search(term: "Starbucks", countryCode: "de")
    }
}
