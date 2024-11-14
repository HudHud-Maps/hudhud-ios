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
import OpenAPIRuntime
import OSLog

// MARK: - HudHudMapLayerStore

@MainActor
public class HudHudMapLayerStore: ObservableObject {

    // MARK: Nested Types

    // Define an enum for button mapStyleTypes
    public enum mapStyleType: String {
        case road, streetView, traffic, saved

        // MARK: Computed Properties

        public var title: String {
            switch self {
            case .road:
                return "Road Alerts"
            case .streetView:
                return "Street View"
            case .traffic:
                return "Traffic"
            case .saved:
                return "Saved"
            }
        }
    }

    // MARK: Properties

    @Published public var hudhudMapLayers: [HudHudMapLayer]?
    @Published public var lastError: Error?
    // This select the buttons under the layer
    @Published public var selectedStyle: Set<mapStyleType> = []
    // This select layer of the map
    @Published public var selectedLayer: Set<HudHudMapLayer> = []
    public let mapStyleTypes: [mapStyleType] = [.traffic, .saved, .streetView, .road]

    // MARK: Lifecycle

    public init() {}

    // MARK: Functions

    public func getMaplayers(baseURL: String) async throws -> [HudHudMapLayer] {
        let response = try await Client.makeClient(using: baseURL).listMapStyles()
        switch response {
        case let .ok(okResponse):
            switch okResponse.body {
            case let .json(jsonResponse):
                let mapLayer: [HudHudMapLayer] = jsonResponse.data.compactMap { mapStyle -> HudHudMapLayer? in
                    guard let styleURL = URL(string: mapStyle.style_url),
                          let thumbnailURL = URL(string: mapStyle.thumbnail_url) else {
                        Logger.parser.error("style_url or thumbnail_url missing, ignoring map layer")
                        return nil
                    }

                    return HudHudMapLayer(name: mapStyle.name, styleUrl: styleURL, thumbnailUrl: thumbnailURL, type: .init(BackendValue: mapStyle._type))
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
        case let .internalServerError(error):
            throw try HudHudClientError.internalServerError(error.body.json.message)
        }
    }

    public func layer(for type: mapStyleType) -> HudHudMapLayer? {
        guard let hudhudMapLayers else { return nil }
        switch type {
        case .traffic:
            return hudhudMapLayers.first { $0.name == "Traffic" }
        case .saved:
            break
        //  return hudhudMapLayers?.first { $0.name == "Saved" }
        case .streetView:
            return hudhudMapLayers.first { $0.name == "Street View" }
        case .road:
            break
            // return hudhudMapLayers?.first { $0.name == "Road Alerts" }
        }
        return nil
    }

    public func buttonStyleAction(for type: mapStyleType) {
        // Toggle the button's selected state
        if self.selectedStyle.contains(type) {
            self.selectedStyle.remove(type)
        } else {
            self.selectedStyle.insert(type)
            if let selectedLayer = self.layer(for: type) {
                self.selectedLayer.insert(selectedLayer)
            }
        }
    }

}

// MARK: - HudHudMapLayer

public struct HudHudMapLayer: Codable, Hashable, RawRepresentable {

    // MARK: Nested Types

    public enum MapType: String, Codable, CustomStringConvertible {
        case mapType = "map_type"
        case mapDetails = "map_details"

        // MARK: Computed Properties

        public var description: String {
            switch self {
            case .mapType:
                return "Map Type"
            case .mapDetails:
                return "Map Details"
            }
        }

        // MARK: Lifecycle

        init(BackendValue value: Components.Schemas.MapStyle._typePayload) {
            switch value {
            case .map_type:
                self = .mapType
            case .map_details:
                self = .mapDetails
            }
        }

    }

    private enum CodingKeys: String, CodingKey {
        case name
        case styleUrl
        case thumbnailUrl
        case type
    }

    // MARK: Properties

    public var name: String
    public var styleUrl: URL
    public var thumbnailUrl: URL
    public var type: MapType

    // MARK: Computed Properties

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self) else {
            return "[]"
        }
        return String(decoding: data, as: UTF8.self)
    }

    // MARK: Lifecycle

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

    public init(name: String, styleUrl: URL, thumbnailUrl: URL, type: MapType) {
        self.name = name
        self.styleUrl = styleUrl
        self.thumbnailUrl = thumbnailUrl
        self.type = type
    }

    // MARK: Static Functions

    // MARK: - Public

    public static func == (lhs: HudHudMapLayer, rhs: HudHudMapLayer) -> Bool {
        return lhs.name == rhs.name &&
            lhs.styleUrl == rhs.styleUrl &&
            lhs.thumbnailUrl == rhs.thumbnailUrl &&
            lhs.type == rhs.type
    }

    // MARK: Functions

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.styleUrl, forKey: .styleUrl)
        try container.encode(self.thumbnailUrl, forKey: .thumbnailUrl)
        try container.encode(self.type, forKey: .type)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
        hasher.combine(self.styleUrl)
        hasher.combine(self.thumbnailUrl)
        hasher.combine(self.type)
    }

}

// swiftlint:enable init_usage
