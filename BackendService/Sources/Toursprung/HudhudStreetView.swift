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

// MARK: - StreetViewItem

public struct StreetViewItem {
    public let id: Int
    public let coordinate: CLLocationCoordinate2D
    public let imageURL: String
}

// MARK: - StreetViewScene

public struct StreetViewScene {
    public let id: Int
    public let name: String
    public let nextId: Int?
    public let nextName: String?
    public let previousId: Int?
    public let previousName: String?
    public let westId: Int?
    public let westName: String?
    public let eastId: Int?
    public let eastName: String?
    public let lat: Double
    public let lon: Double
}

// MARK: - HudhudStreetView

public struct HudhudStreetView {

    // MARK: - Lifecycle

    public init() {}

    // MARK: - Public

    public func getStreetView(lat: Double, lon: Double) async throws -> StreetViewItem? {
        let client = Client(serverURL: URL(string: "https://api.dev.hudhud.sa")!, transport: URLSessionTransport()) // swiftlint:disable:this force_unwrapping
        let response = try await client.getNearestStreetViewImage(query: .init(lat: lat, lon: lon))
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

    public func getStreetViewDetails(id: Int) async throws -> StreetViewItem? {
        let client = Client(serverURL: URL(string: "https://api.dev.hudhud.sa")!, transport: URLSessionTransport()) // swiftlint:disable:this force_unwrapping
        let response = try await client.getStreetViewImage(path: .init(id: id))
        switch response {
        case let .ok(okResponse):
            switch okResponse.body {
            case let .json(jsonResponse):
                let data = jsonResponse.data
                let item = StreetViewItem(id: data.id,
                                          coordinate: CLLocationCoordinate2D(latitude: data.point.lat, longitude: data.point.lon),
                                          imageURL: data.url)
                print(item)
                return item
            }
        case let .undocumented(statusCode: statusCode, payload):
            let bodyString: String? = if let body = payload.body {
                try await String(collecting: body, upTo: 1024 * 1024)
            } else {
                nil
            }
            throw OpenAPIClientError.undocumentedAnswer(status: statusCode, body: bodyString)
        case .badRequest:
            throw HudHudClientError.poiIDNotFound
        case .notFound:
            throw HudHudClientError.poiIDNotFound
        }
    }

    public func getStreetViewScene(id: Int) async throws -> StreetViewScene? {
        let client = Client(serverURL: URL(string: "https://api.dev.hudhud.sa")!, transport: URLSessionTransport()) // swiftlint:disable:this force_unwrapping
        let response = try await client.getStreetViewScene(path: Operations.getStreetViewScene.Input.Path(id: id))
        switch response {
        case let .ok(okResponse):
            switch okResponse.body {
            case let .json(jsonResponse):
                print(jsonResponse)
                let item = jsonResponse.data
                let streetViewScene = StreetViewScene(id: item.id,
                                                      name: item.name,
                                                      nextId: item.next_id,
                                                      nextName: item.next_name,
                                                      previousId: item.previous_id,
                                                      previousName: item.previous_name,
                                                      westId: item.west_id,
                                                      westName: item.west_name,
                                                      eastId: item.east_id,
                                                      eastName: item.east_name,
                                                      lat: item.point.lat,
                                                      lon: item.point.lon)
                return streetViewScene
            }
        case let .undocumented(statusCode: statusCode, payload):
            let bodyString: String? = if let body = payload.body {
                try await String(collecting: body, upTo: 1024 * 1024)
            } else {
                nil
            }
            throw OpenAPIClientError.undocumentedAnswer(status: statusCode, body: bodyString)
        case .badRequest:
            throw HudHudClientError.poiIDNotFound
        case .notFound:
            throw HudHudClientError.poiIDNotFound
        }
    }
}
