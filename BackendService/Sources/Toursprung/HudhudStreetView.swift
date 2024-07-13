//
//  HudhudStreetView.swift
//
//
//  Created by Aziz Dev on 11/07/2024.
//

import CoreLocation
import Foundation
import OpenAPIURLSession
import SFSafeSymbols

public struct StreetViewItem {
    public let id: Int
    public let coordinate: CLLocationCoordinate2D
    public let imageURL: String
}

public struct HudhudStreetView {

    public init() {}

    public func getStreetView(lat: Double, lon: Double) async throws -> StreetViewItem? {
        let client = Client(serverURL: URL(string: "https://api.dev.hudhud.sa")!, transport: URLSessionTransport())    // swiftlint:disable:this force_unwrapping
        let response = try await client.GetNearestStreetViewImage(query: .init(lat: lat, lon: lon))
        switch response {
        case let .ok(okResponse):
            switch okResponse.body {
            case let .json(jsonResponse):
                if let data = jsonResponse.data {
                    let item = StreetViewItem(id: data.id,
                                              coordinate: CLLocationCoordinate2D(latitude: data.point.lat, longitude: data.point.lon),
                                              imageURL: data.url)
                    print(item)
                    return item
                }
                return nil
            }
        case let .undocumented(statusCode: statusCode, payload):
            let bodyString: String? = if let body = payload.body {
                try await String(collecting: body, upTo: 1024 * 1024)
            } else {
                nil
            }
            throw OpenAPIClientError.undocumentedAnswer(status: statusCode, body: bodyString)
        }
    }
}
