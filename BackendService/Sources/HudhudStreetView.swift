//
//  HudhudStreetView.swift
//	HudHud
//
//  Created by Aziz Dev on 11/07/2024.
//  Copyright © 2024 HudHud. All rights reserved.
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

public struct StreetViewScene: Equatable {
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

    // MARK: Lifecycle

    public init() {}

    // MARK: Functions

    public func getStreetView(lat: Double, lon: Double, baseURL: String) async throws -> StreetViewItem? {
        let query = Operations.getNearestStreetViewImage.Input.Query(lat: lat, lon: lon)
        let input = Operations.getNearestStreetViewImage.Input(query: query)
        let response = try await Client.makeClient(using: baseURL).getNearestStreetViewImage(input)
        switch response {
        case let .ok(okResponse):
            switch okResponse.body {
            case let .json(jsonResponse):
                let data = jsonResponse.data
                let item = StreetViewItem(id: data.value1.id,
                                          coordinate: CLLocationCoordinate2D(latitude: data.value1.point.lat, longitude: data.value1.point.lon),
                                          imageURL: data.value1.url)
                return item
            }
        case let .undocumented(statusCode: statusCode, payload):
            let bodyString: String? = if let body = payload.body {
                try await String(collecting: body, upTo: 1024 * 1024)
            } else {
                nil
            }
            throw OpenAPIClientError.undocumentedAnswer(status: statusCode, body: bodyString)
        case let .internalServerError(error):
            throw try HudHudClientError.internalServerError(error.body.json.message.debugDescription)
        case let .badRequest(error):
            throw try HudHudClientError.badRequest(error.body.json.message.debugDescription)
        }
    }

    public func getStreetViewDetails(id: Int, baseURL: String) async throws -> StreetViewItem? {
        let response = try await Client.makeClient(using: baseURL).getStreetViewImage(
            path: Operations.getStreetViewImage.Input.Path(id: id)
        )
        switch response {
        case let .ok(okResponse):
            switch okResponse.body {
            case let .json(jsonResponse):
                let data = jsonResponse.data.value1
                let item = StreetViewItem(id: data.id,
                                          coordinate: CLLocationCoordinate2D(latitude: data.point.lat, longitude: data.point.lon),
                                          imageURL: data.url)
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
        case let .internalServerError(error):
            throw try HudHudClientError.internalServerError(error.body.json.message.debugDescription)
        }
    }

    public func getStreetViewScene(id: Int, baseURL: String) async throws -> StreetViewScene? {
        let response = try await Client.makeClient(using: baseURL).getStreetViewScene(path: Operations.getStreetViewScene.Input.Path(id: id))
        switch response {
        case let .ok(okResponse):
            switch okResponse.body {
            case let .json(jsonResponse):
                let item = jsonResponse.data.value1
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
        case let .internalServerError(error):
            throw try HudHudClientError.internalServerError(error.body.json.message.debugDescription)
        }
    }

    public func getStreetViewSceneBBox(box: [Double]) async throws -> StreetViewScene? {
        let client = Client(serverURL: URL(string: "https://api.dev.hudhud.sa")!, transport: URLSessionTransport()) // swiftlint:disable:this force_unwrapping

        let bboxString = box.compactMap { $0 }.map { String($0) }.joined(separator: ",")
        let query = Operations.getStreetViewSceneBBox.Input.Query(bbox: bboxString)
        let input = Operations.getStreetViewSceneBBox.Input(query: query)

        let response = try await client.getStreetViewSceneBBox(input)
        switch response {
        case let .ok(okResponse):
            switch okResponse.body {
            case let .json(jsonResponse):
                let item = jsonResponse.data.value1
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
        case let .internalServerError(error):
            throw try HudHudClientError.internalServerError(error.body.json.message.debugDescription)
        case .badRequest:
            throw HudHudClientError.poiIDNotFound
        case .notFound:
            throw HudHudClientError.poiIDNotFound
        }
    }

}
