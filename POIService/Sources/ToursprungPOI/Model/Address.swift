//
//  Address.swift
//  ToursprungPOI
//
//  Created by Patrick Kladek on 10.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

public struct Address: Codable, Equatable, Hashable, Sendable {
	public let hamlet: String?
	public let county: String?
	public let state: String?
	public let iso31662Lvl4: String?
	public let country: String?
	public let countryCode: String?
	public let town: String?
	public let postcode: String?
	public let village: String?
	public let iso31662Lvl6: String?
	public let municipality: String?
	public let region: String?
	public let natural: String?
	public let stateDistrict: String?
	public let city: String?
	public let road: String?
	public let quarter: String?
	public let suburb: String?
	public let iso31662Lvl3: String?

	enum CodingKeys: String, CodingKey {
		case hamlet = "hamlet"
		case county = "county"
		case state = "state"
		case iso31662Lvl4 = "ISO3166-2-lvl4"
		case country = "country"
		case countryCode = "country_code"
		case town = "town"
		case postcode = "postcode"
		case village = "village"
		case iso31662Lvl6 = "ISO3166-2-lvl6"
		case municipality = "municipality"
		case region = "region"
		case natural = "natural"
		case stateDistrict = "state_district"
		case city = "city"
		case road = "road"
		case quarter = "quarter"
		case suburb = "suburb"
		case iso31662Lvl3 = "ISO3166-2-lvl3"
	}

	public init(hamlet: String?, county: String?, state: String?, iso31662Lvl4: String?, country: String?, countryCode: String?, town: String?, postcode: String?, village: String?, iso31662Lvl6: String?, municipality: String?, region: String?, natural: String?, stateDistrict: String?, city: String?, road: String?, quarter: String?, suburb: String?, iso31662Lvl3: String?) {
		self.hamlet = hamlet
		self.county = county
		self.state = state
		self.iso31662Lvl4 = iso31662Lvl4
		self.country = country
		self.countryCode = countryCode
		self.town = town
		self.postcode = postcode
		self.village = village
		self.iso31662Lvl6 = iso31662Lvl6
		self.municipality = municipality
		self.region = region
		self.natural = natural
		self.stateDistrict = stateDistrict
		self.city = city
		self.road = road
		self.quarter = quarter
		self.suburb = suburb
		self.iso31662Lvl3 = iso31662Lvl3
	}
}

extension Address: CustomStringConvertible {

	public var description: String {
		return [
			self.road,
			self.suburb,
			self.quarter,
			self.village,
			self.town,
			self.city,
			self.county,
			self.state,
			self.postcode,
			self.country
		].compactMap { $0 }.joined(separator: ", ")
	}
}
