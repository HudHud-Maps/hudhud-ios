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

    public func getMaplayers(baseURL: String) async throws -> [HudHudMapLayer] {
        let urlSessionConfiguration = URLSessionConfiguration.default
        urlSessionConfiguration.waitsForConnectivity = true
        urlSessionConfiguration.timeoutIntervalForResource = 60 // seconds

        let urlSession = URLSession(configuration: urlSessionConfiguration)

        let transportConfiguration = URLSessionTransport.Configuration(session: urlSession)

        let transport = URLSessionTransport(configuration: transportConfiguration)

        let response = try await Client.makeClient(using: baseURL, transport: transport).listMapStyles()
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
                    return HudHudMapLayer(name: mapStyle.name, styleUrl: styleURL, thumbnailUrl: thumbnailURL, type: .init(BackendValue: mapStyle._type.rawValue))
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

    // MARK: - Lifecycle

    public init() {}

}

// MARK: - HudHudMapLayer

public struct HudHudMapLayer: Codable, Hashable, RawRepresentable {
    public var name: String
    public var styleUrl: URL
    public var thumbnailUrl: URL
    public var type: MapType

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self) else {
            return "[]"
        }
        return String(decoding: data, as: UTF8.self)
    }

    public enum MapType: String, Codable, CustomStringConvertible {
        case mapType = "map_type"
        case mapDetails = "map_details"

        public var description: String {
            switch self {
            case .mapType:
                return "Map Type"
            case .mapDetails:
                return "Map Details"
            }
        }

        // MARK: - Lifecycle

        public init(BackendValue value: String) {
            switch value {
            case "map_type":
                self = .mapType
            case "map_details":
                self = .mapDetails
            default:
                self = .mapType
            }
        }

    }

    private enum CodingKeys: String, CodingKey {
        case name
        case styleUrl
        case thumbnailUrl
        case type
    }

    public init?(rawValue: RawValue) {
        let decoder = JSONDecoder()
        guard let data = rawValue.data(using: .utf8) else {
            return nil
        }
        do {
            let decoded = try decoder.decode(HudHudMapLayer.self, from: data)
            self = decoded
        } catch {
            Logger().error("Decoding error: \(error)")
            return nil
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.styleUrl = try container.decode(URL.self, forKey: .styleUrl)
        self.thumbnailUrl = try container.decode(URL.self, forKey: .thumbnailUrl)
        self.type = try container.decode(MapType.self, forKey: .type)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.styleUrl, forKey: .styleUrl)
        try container.encode(self.thumbnailUrl, forKey: .thumbnailUrl)
        try container.encode(self.type, forKey: .type)
    }

    // MARK: - Lifecycle

    public init(name: String, styleUrl: URL, thumbnailUrl: URL, type: MapType) {
        self.name = name
        self.styleUrl = styleUrl
        self.thumbnailUrl = thumbnailUrl
        self.type = type
    }

    // MARK: - Public

    public static func == (lhs: HudHudMapLayer, rhs: HudHudMapLayer) -> Bool {
        return lhs.name == rhs.name &&
            lhs.styleUrl == rhs.styleUrl &&
            lhs.thumbnailUrl == rhs.thumbnailUrl &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
        hasher.combine(self.styleUrl)
        hasher.combine(self.thumbnailUrl)
        hasher.combine(self.type)
    }

}

// swiftlint:enable init_usage
