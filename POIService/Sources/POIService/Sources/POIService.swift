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
	func lookup(prediction: Any) async throws -> [ResolvedItem]
	func predict(term: String) async throws -> [AnyDisplayableAsRow]
}

// MARK: - PredictionResult

public enum PredictionResult: Hashable, Codable {
	case apple(completion: MKLocalSearchCompletion)
	case appleResolved
	case toursprung

	enum CodingKeys: CodingKey {
		case appleResolved
		case toursprung
	}
}

// MARK: - DisplayableAsRow

public protocol DisplayableAsRow: Identifiable {
	var id: String { get }
	var title: String { get }
	var subtitle: String { get }
	var icon: Image { get }

	var onTap: (() -> Void)? { get }
	func resolve(in provider: ApplePOI) async throws -> [AnyDisplayableAsRow]
}

// MARK: - AnyDisplayableAsRow

public struct AnyDisplayableAsRow: DisplayableAsRow {

	public var title: String {
		self.innerModel.title
	}

	public var subtitle: String {
		self.innerModel.subtitle
	}

	public var icon: Image {
		self.innerModel.icon
	}

	public var onTap: (() -> Void)? {
		self.innerModel.onTap
	}

	public var innerModel: any DisplayableAsRow

	public var id: String { self.innerModel.id }

	// MARK: - Lifecycle

	public init(_ model: some DisplayableAsRow) {
		self.innerModel = model // Automatically casts to “any” type
	}

	// MARK: - Public

	public static func == (lhs: AnyDisplayableAsRow, rhs: AnyDisplayableAsRow) -> Bool {
		return lhs.id == rhs.id
	}

	public func resolve(in provider: ApplePOI) async throws -> [AnyDisplayableAsRow] {
		return try await self.innerModel.resolve(in: provider)
	}

}

// MARK: - PredictionItem

public struct PredictionItem: DisplayableAsRow {

	public var id: String
	public var title: String
	public var subtitle: String
	public var icon: Image
	public var type: PredictionResult
	public var onTap: (() -> Void)?

	// MARK: - Lifecycle

	public init(id: String, title: String, subtitle: String, icon: Image, type: PredictionResult, onTap: (() -> Void)? = nil) {
		self.id = id
		self.title = title
		self.subtitle = subtitle
		self.icon = icon
		self.type = type
		self.onTap = onTap
	}

	// MARK: - Public

	public static func == (lhs: PredictionItem, rhs: PredictionItem) -> Bool {
		return lhs.id == rhs.id
	}

	public func resolve(in provider: ApplePOI) async throws -> [AnyDisplayableAsRow] {
		guard case let .apple(completion) = self.type else { return [] }

		let resolved = try await provider.lookup(prediction: completion)
		let mapped = resolved.map {
			AnyDisplayableAsRow($0)
		}
		return mapped
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(self.id)
		hasher.combine(self.title)
		hasher.combine(self.subtitle)
	}

}

// MARK: - ResolvedItem

public struct ResolvedItem: DisplayableAsRow, Codable, Equatable, Hashable, CustomStringConvertible {
	public var id: String
	public var title: String
	public var subtitle: String
	public var icon: Image {
		return Image(systemSymbol: .pinFill)
	}

	public let type: PredictionResult
	public var coordinate: CLLocationCoordinate2D
	public var onTap: (() -> Void)?
	public var phone: String?
	public var website: URL?
	public var userInfo: [String: AnyHashable] = [:]

	enum CodingKeys: String, CodingKey {
		case id, title, subtitle, type, coordinate
	}

	public var description: String {
		return "\(self.title), \(self.subtitle), coordinate: \(self.coordinate)"
	}

	// MARK: - Lifecycle

	public init(id: String, title: String, subtitle: String, type: PredictionResult, coordinate: CLLocationCoordinate2D, phone: String? = nil, website: URL? = nil, onTap: (() -> Void)? = nil) {
		self.id = id
		self.title = title
		self.subtitle = subtitle
		self.type = type
		self.coordinate = coordinate
		self.onTap = onTap
		self.phone = phone
		self.website = website
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.id = try container.decode(String.self, forKey: .id)
		self.title = try container.decode(String.self, forKey: .title)
		self.subtitle = try container.decode(String.self, forKey: .subtitle)
		self.type = try container.decode(PredictionResult.self, forKey: .type)
		self.coordinate = try container.decode(CLLocationCoordinate2D.self, forKey: .coordinate)
	}

	// MARK: - Public

	public static func == (lhs: ResolvedItem, rhs: ResolvedItem) -> Bool {
		return lhs.id == rhs.id
	}

	public func resolve(in _: ApplePOI) async throws -> [AnyDisplayableAsRow] {
		return [AnyDisplayableAsRow(self)]
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.id, forKey: .id)
		try container.encode(self.title, forKey: .title)
		try container.encode(self.subtitle, forKey: .subtitle)
		try container.encode(self.coordinate, forKey: .coordinate)
		try container.encode(self.type, forKey: .type)
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(self.id)
		hasher.combine(self.title)
		hasher.combine(self.subtitle)
	}
}

public extension PredictionItem {

	static let ketchup = PredictionItem(id: UUID().uuidString,
										title: "Ketch up",
										subtitle: "Bluewaters Island - off Jumeirah Beach Residence",
										icon: .init(systemSymbol: .pin),
										type: .appleResolved)
	static let starbucks = PredictionItem(id: UUID().uuidString,
										  title: "Starbucks",
										  subtitle: "The Beach",
										  icon: .init(systemSymbol: .pin),
										  type: .appleResolved)
	static let publicPlace = PredictionItem(id: UUID().uuidString,
											title: "publicPlace",
											subtitle: "Garden - Alyasmen - Riyadh",
											icon: .init(systemSymbol: .pin),
											type: .appleResolved)
	static let artwork = PredictionItem(id: UUID().uuidString,
										title: "Artwork",
										subtitle: "artwork - Al-Olya - Riyadh",
										icon: .init(systemSymbol: .pin),
										type: .appleResolved)
	static let pharmacy = PredictionItem(id: UUID().uuidString,
										 title: "Pharmacy",
										 subtitle: "Al-Olya - Riyadh",
										 icon: .init(systemSymbol: .pin),
										 type: .appleResolved)
	static let supermarket = PredictionItem(id: UUID().uuidString,
											title: "Supermarket",
											subtitle: "Al-Narjs - Riyadh",
											icon: .init(systemSymbol: .pin),
											type: .appleResolved)
}

public extension ResolvedItem {

	static let ketchup = ResolvedItem(id: UUID().uuidString,
									  title: "Ketch up",
									  subtitle: "Bluewaters Island - off Jumeirah Beach Residence",
									  type: .toursprung,
									  coordinate: CLLocationCoordinate2D(latitude: 24.723583614203136, longitude: 46.633232873031076),
									  phone: "0503539560",
									  website: URL(string: "https://hudhud.sa"))

	static let starbucks = ResolvedItem(id: UUID().uuidString,
										title: "Starbucks",
										subtitle: "The Beach",
										type: .toursprung,
										coordinate: CLLocationCoordinate2D(latitude: 24.732211928084162, longitude: 46.87863163915118),
										phone: "0503539560",
										website: URL(string: "https://hudhud.sa"))

	static let publicPlace = ResolvedItem(id: UUID().uuidString,
										  title: "publicPlace",
										  subtitle: "Garden - Alyasmen - Riyadh",
										  type: .toursprung,
										  coordinate: CLLocationCoordinate2D(latitude: 24.595375923107532, longitude: 46.598253176098346))

	static let artwork = ResolvedItem(id: UUID().uuidString,
									  title: "Artwork",
									  subtitle: "artwork - Al-Olya - Riyadh",
									  type: .toursprung,
									  coordinate: CLLocationCoordinate2D(latitude: 24.77888564128478, longitude: 46.61555160031425),
									  phone: "0503539560",
									  website: URL(string: "https://hudhud.sa"))

	static let pharmacy = ResolvedItem(id: UUID().uuidString,
									   title: "Pharmacy",
									   subtitle: "Al-Olya - Riyadh",
									   type: .toursprung,
									   coordinate: CLLocationCoordinate2D(latitude: 24.78796199972764, longitude: 46.69371856758005),
									   phone: "0503539560",
									   website: URL(string: "https://hudhud.sa"))

	static let supermarket = ResolvedItem(id: UUID().uuidString,
										  title: "Supermarket",
										  subtitle: "Al-Narjs - Riyadh",
										  type: .toursprung,
										  coordinate: CLLocationCoordinate2D(latitude: 24.79671388339593, longitude: 46.70810150540095),
										  phone: "0503539560",
										  website: URL(string: "https://hudhud.sa"))
}

public extension AnyDisplayableAsRow {

	static let ketchup = AnyDisplayableAsRow(ResolvedItem.ketchup)
	static let starbucks = AnyDisplayableAsRow(ResolvedItem.starbucks)
	static let publicPlace = AnyDisplayableAsRow(ResolvedItem.publicPlace)
	static let artwork = AnyDisplayableAsRow(ResolvedItem.artwork)
	static let pharmacy = AnyDisplayableAsRow(ResolvedItem.pharmacy)
	static let supermarket = AnyDisplayableAsRow(ResolvedItem.supermarket)
}

/*
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
 */
