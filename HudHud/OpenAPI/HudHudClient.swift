//
//  HudHudClient.swift
//  HudHud
//
//  Created by patrick on 29.05.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation
import OpenAPIURLSession
import POIService
import SFSafeSymbols

// MARK: - OpenAPIClientError

// generic errors that could come from any API
enum OpenAPIClientError: Error {
    case notFound
    case undocumentedAnswer(status: Int, body: String?)
    case unexpectedType(body: String)
}

// MARK: - HudHudClientError

// errors specific to our backend
enum HudHudClientError: Error {
    case poiIDNotFound

}

// MARK: - HudHudClient

struct HudHudClient {
    // This is a demo of how to use the client. This needs to be moved into POIService
    // once the API is actually available - problem is that the OpenAPI spec contains more
    // than just POI things. POIService will either need to be renamed to HudHudClient or
    // we'll need to reintegrate the package into the app itself.
    func resolveItem(id: String) async throws -> ResolvedItem {
        let client = Client(serverURL: URL(string: "https://hudhud.sa")!, transport: URLSessionTransport())

        let response = try await client.getPoi(path: .init(id: id), headers: .init(Accept_hyphen_Language: Locale.preferredLanguages.first ?? "en-US"))
        switch response {
        case let .ok(okResponse):
            switch okResponse.body {
            case let .json(jsonResponse):
                return ResolvedItem(id: jsonResponse.data.id, title: jsonResponse.data.name, subtitle: jsonResponse.data.address, category: jsonResponse.data.category, symbol: .pin, type: .appleResolved, coordinate: CLLocationCoordinate2D(latitude: jsonResponse.data.coordinates.lat, longitude: jsonResponse.data.coordinates.lon), phone: jsonResponse.data.phone_number, website: URL(string: jsonResponse.data.website))
            }
        case .notFound:
            throw HudHudClientError.poiIDNotFound
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
