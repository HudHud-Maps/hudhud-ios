// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let pOIElement = try? newJSONDecoder().decode(POIElement.self, from: jsonData)
//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

import Foundation

// MARK: - POIElement
public struct POIElement: Codable, Equatable, Sendable {
    public let placeID: Int
    public let licence: String
    public let osmType: String
    public let osmID: Int
    public let boundingbox: [String]
    public let lat: String
    public let lon: String
    public let displayName: String
    public let poiClass: String
    public let type: String
    public let importance: Double
    public let address: Address
    public let category: String

    enum CodingKeys: String, CodingKey {
        case placeID = "place_id"
        case licence = "licence"
        case osmType = "osm_type"
        case osmID = "osm_id"
        case boundingbox = "boundingbox"
        case lat = "lat"
        case lon = "lon"
        case displayName = "display_name"
        case poiClass = "class"
        case type = "type"
        case importance = "importance"
        case address = "address"
        case category = "category"
    }

    public init(placeID: Int, licence: String, osmType: String, osmID: Int, boundingbox: [String], lat: String, lon: String, displayName: String, poiClass: String, type: String, importance: Double, address: Address, category: String) {
        self.placeID = placeID
        self.licence = licence
        self.osmType = osmType
        self.osmID = osmID
        self.boundingbox = boundingbox
        self.lat = lat
        self.lon = lon
        self.displayName = displayName
        self.poiClass = poiClass
        self.type = type
        self.importance = importance
        self.address = address
        self.category = category
    }
}
