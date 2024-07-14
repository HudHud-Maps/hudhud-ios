//
//  POIElement.swift
//  ToursprungPOI
//
//  Created by Patrick Kladek on 10.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

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
        case licence
        case osmType = "osm_type"
        case osmID = "osm_id"
        case boundingbox
        case lat
        case lon
        case displayName = "display_name"
        case poiClass = "class"
        case type
        case importance
        case address
        case category
    }

    // MARK: - Lifecycle

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

// MARK: - CustomStringConvertible

extension POIElement: CustomStringConvertible {

    public var description: String {
        return "POI Element"
    }
}

public extension POIElement {

    static let starbucksKualaLumpur = POIElement(placeID: 374_426_437,
                                                 licence: "Data © OpenStreetMap contributors, ODbL 1.0. https://osm.org/copyright",
                                                 osmType: "node",
                                                 osmID: 11_363_949_513,
                                                 boundingbox: ["3.177196", "3.177296", "101.7506882", "101.7507882"],
                                                 lat: "3.177246",
                                                 lon: "101.7507382",
                                                 displayName: "Starbucks, Kuala Lumpur, Malaysia",
                                                 poiClass: "amenity",
                                                 type: "cafe",
                                                 importance: 0.6758606469435616,
                                                 address: Address(hamlet: nil,
                                                                  county: nil,
                                                                  state: nil,
                                                                  iso31662Lvl4: "MY-14",
                                                                  country: "Malaysia",
                                                                  countryCode: "my",
                                                                  town: nil,
                                                                  postcode: "54200",
                                                                  village: nil,
                                                                  iso31662Lvl6: nil,
                                                                  municipality: nil,
                                                                  region: nil,
                                                                  natural: nil,
                                                                  stateDistrict: nil,
                                                                  city: "Kuala Lumpur",
                                                                  road: "Jalan Taman Setiawangsa",
                                                                  quarter: nil,
                                                                  suburb: "Setiawangsa",
                                                                  iso31662Lvl3: nil),
                                                 category: "poi")
}
