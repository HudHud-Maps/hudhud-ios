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

// MARK: CustomStringConvertible

extension POIElement: CustomStringConvertible {

	public var description: String {
		return "POI Element"
	}
}
