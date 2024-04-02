//
//  POIService.swift
//  POIService
//
//  Created by Patrick Kladek on 01.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation
import MapKit
import SFSafeSymbols
import SwiftUI

// MARK: - POIServiceProtocol

public protocol POIServiceProtocol {

	static var serviceName: String { get }
	func lookup(prediction: PredictionResult) async throws -> [Row]
	func predict(term: String) async throws -> [Row]
}

// MARK: - PredictionResult

public enum PredictionResult: Hashable {
	case apple(completion: MKLocalSearchCompletion)
	case toursprung(result: Row)
}

// MARK: - POI

public class POI: Codable, Hashable, Identifiable {

	public var id: Int
	public var title: String
	public var subtitle: String
	public var locationCoordinate: CLLocationCoordinate2D?
	public var type: String
	public var userInfo: [String: AnyHashable] = [:]

	// MARK: - Codable Protocol

	enum CodingKeys: String, CodingKey {
		case id, title, subtitle, locationCoordinate, type
	}

	// MARK: - Lifecycle

	public init(id: Int = .random(in: 0 ... 1_000_000), title: String, subtitle: String, locationCoordinate: CLLocationCoordinate2D, type: String) {
		self.id = id
		self.title = title
		self.subtitle = subtitle
		self.locationCoordinate = locationCoordinate
		self.type = type
	}

	public required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.id = try container.decode(Int.self, forKey: .id)
		self.title = try container.decode(String.self, forKey: .title)
		self.subtitle = try container.decode(String.self, forKey: .subtitle)
		self.locationCoordinate = try container.decode(CLLocationCoordinate2D.self, forKey: .locationCoordinate)
		self.type = try container.decode(String.self, forKey: .type)
	}

	// MARK: - Public

	public static func == (lhs: POI, rhs: POI) -> Bool {
		return lhs.title == rhs.title && lhs.subtitle == rhs.subtitle
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.id, forKey: .id)
		try container.encode(self.title, forKey: .title)
		try container.encode(self.subtitle, forKey: .subtitle)
		try container.encode(self.locationCoordinate, forKey: .locationCoordinate)
		try container.encode(self.type, forKey: .type)
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(self.title)
		hasher.combine(self.subtitle)
	}

}

public extension POI {

	var icon: Image {
		switch self.type.lowercased() {
		case "cafe":
			return Image(systemSymbol: .cupAndSaucerFill)
		case "restaurant":
			return Image(systemSymbol: .forkKnife)
		default:
			return Image(systemSymbol: .mappin)
		}
	}
}

public extension POI {

	var iconColor: Color {
		switch self.type.lowercased() {
		case "cafe":
			return .brown
		case "restaurant":
			return .orange
		case "accomodation", "appartment", "camp_site", "caravan_site", "chalet", "guest_house", "hostel", "hotel", "motel", "wilderness_hut":
			return .green
		case "alpine_hut":
			return .purple
		// Animals
		case "animal_boarding", "animal_shelter", "veterinary":
			return .red
		// Arts and Culture
		case "arts_centre", "gallery", "museum":
			return .pink
		case "library":
			return .brown
		case "place_of_worship":
			return .brown
		case "studio":
			return .purple
		// Education
		case "college", "kindergarten", "language_school", "music_school", "school", "university":
			return .yellow
		case "driving_school":
			return .yellow

		// Facilities
		case "bench", "shelter", "table", "toilets":
			return .cyan
		case "clock", "post_box", "telephone":
			return .cyan
		case "drinking_water", "water_point":
			return .cyan
		case "fountain":
			return .cyan
		case "recycling", "recycling_station", "waste_basket", "waste_disposal":
			return .cyan
		case "shower":
			return .cyan
		// Financial
		case "atm":
			return .green
		case "bank", "bureau_de_change":
			return .green

		// Healthcare
		case "baby_hatch", "clinic", "dentist", "doctors", "hospital", "nursing_home", "retirement_home", "social_facility":
			return .cyan

		// Leisure and Entertainment
		case "amusement_arcade", "adult_gaming_centre", "cinema", "nightclub", "theme_park", "zoo":
			return .red
		case "beach_resort", "park", "picnic_site", "playground":
			return .red
		case "dog_park":
			return .red
		case "swimming_pool", "water_park":
			return .cyan
		// Tourism
		case "aquarium", "artwork", "attraction", "viewpoint":
			return .cyan
		case "information":
			return .yellow

		// Shop
		case "bakery", "beverages", "butcher", "cheese", "chocolate", "coffee", "confectionery", "dairy", "deli", "farm", "fish", "greengrocer", "tea":
			return .brown
		case "bicycle", "bicycle_parking", "bicycle_rental", "bicycle_repair_station":
			return .cyan
		case "book", "books":
			return .brown
		case "clothes", "fashion":
			return .pink
		case "convenience", "supermarket":
			return .red
		case "pharmacy":
			return .cyan
		// Food & Drink
		case "bar", "biergarten", "fast_food", "food_court", "ice_cream", "pub":
			return .red

		// Transport
		case "boat_sharing", "bus_station", "bus_stop", "car_rental", "car_repair", "car_sharing", "car_wash", "charging_station", "ev_charging", "ferry_terminal", "fuel", "motorcycle_parking", "parking", "parking_entrance", "parking_space", "taxi":
			return .brown
		case "individual":
			return .green
		case "search nearby":
			return .blue
		default:
			return .blue
		}
	}
}

// MARK: - CustomStringConvertible

extension POI: CustomStringConvertible {
	public var description: String {
		return "\(self.title) - \(self.subtitle)"
	}
}

public extension POI {
	static let ketchup = POI(title: "Ketch up - Dubai",
							 subtitle: "Bluewaters Island - off Jumeirah Beach Residence - Bluewaters Island - Dubai",
							 locationCoordinate: CLLocationCoordinate2D(latitude: 25.077744998955207, longitude: 55.124647403691284),
							 type: "Restaurant")
	static let starbucks = POI(title: "Starbucks",
							   subtitle: "The Beach - Jumeirah Beach Residence - Dubai",
							   locationCoordinate: CLLocationCoordinate2D(latitude: 25.075671955460354, longitude: 55.13046336047564),
							   type: "Cafe")
	static let publicPlace = POI(title: "publicPlace",
								 subtitle: "Garden - Alyasmen - Riyadh",
								 locationCoordinate: CLLocationCoordinate2D(latitude: 25.075671955460354, longitude: 55.13046336047564),
								 type: "publicPlace")
	static let artwork = POI(title: "Artwork",
							 subtitle: "artwork - Al-Olya - Riyadh",
							 locationCoordinate: CLLocationCoordinate2D(latitude: 25.075671955460354, longitude: 55.13046336047564),
							 type: "artwork")
	static let pharmacy = POI(title: "Pharmacy",
							  subtitle: "Al-Olya - Riyadh",
							  locationCoordinate: CLLocationCoordinate2D(latitude: 25.075671955460354, longitude: 55.13046336047564),
							  type: "pharmacy")
	static let supermarket = POI(title: "Supermarket",
								 subtitle: "Al-Narjs - Riyadh",
								 locationCoordinate: CLLocationCoordinate2D(latitude: 25.075671955460354, longitude: 55.13046336047564),
								 type: "supermarket")
}

// MARK: - CLLocationCoordinate2D + Codable

extension CLLocationCoordinate2D: Codable {
	public enum CodingKeys: String, CodingKey {
		case latitude
		case longitude
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(latitude, forKey: .latitude)
		try container.encode(longitude, forKey: .longitude)
	}

	public init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		self.init()
		latitude = try values.decode(Double.self, forKey: .latitude)
		longitude = try values.decode(Double.self, forKey: .longitude)
	}
}
