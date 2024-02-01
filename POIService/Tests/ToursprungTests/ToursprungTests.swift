import XCTest
@testable import Toursprung

final class ToursprungTests: XCTestCase {

    func testGeocoder() async throws {
        let geocoder = Geocoder(session: .shared)

        let pois = try await geocoder.search(term: "Starbucks", countryCode: "de")
        print(pois)
    }
}
