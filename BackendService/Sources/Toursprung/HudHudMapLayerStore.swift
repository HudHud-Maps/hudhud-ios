//
//  HudHudMapLayerStore.swift
//  BackendService
//
//  Created by Alaa . on 12/06/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//
// swiftlint:disable init_usage

import CoreLocation
import Foundation
import OpenAPIURLSession
import OSLog

// MARK: - HudHudMapLayerStore

public class HudHudMapLayerStore: ObservableObject {

    @Published public var hudhudMapLayers: [HudHudMapLayer]?
    @Published public var lastError: Error?

    // MARK: - Lifecycle

    public init() {}

    // MARK: - Public

    public func getMaplayers() async throws -> [HudHudMapLayer] {
        let urlSessionConfiguration = URLSessionConfiguration.default
        urlSessionConfiguration.waitsForConnectivity = true
        urlSessionConfiguration.timeoutIntervalForResource = 60 // seconds

        let urlSession = URLSession(configuration: urlSessionConfiguration)

        let transportConfiguration = URLSessionTransport.Configuration(session: urlSession)

        let transport = URLSessionTransport(configuration: transportConfiguration)
        let client = Client(serverURL: URL(string: "https://api.dev.hudhud.sa")!, transport: transport) // swiftlint:disable:this force_unwrapping

        let response = try await client.listMapStyles()
        switch response {
        case let .ok(okResponse):
            switch okResponse.body {
            case let .json(jsonResponse):
                let mapLayer: [HudHudMapLayer] = jsonResponse.data.compactMap { mapStyle in
                    guard let styleURL = URL(string: mapStyle.style_url),
                          let thumbnailURL = URL(string: mapStyle.thumbnail_url) else {
                        Logger.parser.error("style_url or thumbnail_url missing, ignoring map layer")
                        return nil
                    }
                    return HudHudMapLayer(name: mapStyle.name, styleUrl: styleURL, thumbnailUrl: thumbnailURL, type: mapStyle._type.rawValue)
                }
                return mapLayer
            }
        case let .undocumented(statusCode: statusCode, payload):
            let bodyString: String? = if let body = payload.body {
                try await String(collecting: body, upTo: 1024 * 1024)
            } else {
                nil
            }
            self.lastError = OpenAPIClientError.undocumentedAnswer(status: statusCode, body: bodyString)
            throw OpenAPIClientError.undocumentedAnswer(status: statusCode, body: bodyString)
        }
    }
}

// MARK: - HudHudMapLayer

public struct HudHudMapLayer: Hashable {
    public let name: String
    public let styleUrl: URL
    public let thumbnailUrl: URL
    public let type: String

    public var displayType: String {
        switch self.type {
        case "map_type":
            return "Map Type"
        case "map_details":
            return "Map Details"
        default:
            return self.type
        }
    }
}

// swiftlint:enable init_usage
