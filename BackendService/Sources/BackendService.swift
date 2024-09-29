//
//  BackendService.swift
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
    func lookup(id: String, prediction: Any, baseURL: String) async throws -> [ResolvedItem]
    func predict(term: String, coordinates: CLLocationCoordinate2D?, baseURL: String) async throws -> POIResponse
}

// MARK: - PredictionResult

public enum PredictionResult: Hashable, Codable {
    case apple(completion: MKLocalSearchCompletion)
    case appleResolved
    case hudhud

    // MARK: Nested Types

    enum CodingKeys: CodingKey {
        case appleResolved
        case hudhud
    }
}

// MARK: - DisplayableAsRow

public protocol DisplayableAsRow: Identifiable, Hashable {
    var id: String { get }
    var title: String { get }
    var subtitle: String? { get }
    var symbol: SFSymbol { get }

    func resolve(in provider: ApplePOI, baseURL: String) async throws -> [AnyDisplayableAsRow]
    func resolve(in provider: HudHudPOI, baseURL: String) async throws -> [AnyDisplayableAsRow]
}

// MARK: - AnyDisplayableAsRow

public struct AnyDisplayableAsRow: DisplayableAsRow {

    // MARK: Properties

    public var innerModel: any DisplayableAsRow

    // MARK: Computed Properties

    public var title: String {
        self.innerModel.title
    }

    public var subtitle: String? {
        self.innerModel.subtitle
    }

    public var symbol: SFSymbol {
        self.innerModel.symbol
    }

    public var id: String { self.innerModel.id }

    // MARK: Lifecycle

    public init(_ model: some DisplayableAsRow) {
        self.innerModel = model // Automatically casts to “any” type
    }

    // MARK: Static Functions

    // MARK: - Public

    public static func == (lhs: AnyDisplayableAsRow, rhs: AnyDisplayableAsRow) -> Bool {
        return lhs.id == rhs.id
    }

    // MARK: Functions

    public func resolve(in provider: ApplePOI, baseURL: String) async throws -> [AnyDisplayableAsRow] {
        return try await self.innerModel.resolve(in: provider, baseURL: baseURL)
    }

    public func resolve(in provider: HudHudPOI, baseURL: String) async throws -> [AnyDisplayableAsRow] {
        return try await self.innerModel.resolve(in: provider, baseURL: baseURL)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.title)
        hasher.combine(self.subtitle)
        hasher.combine(self.symbol)
        hasher.combine(self.id)
    }
}

// MARK: - PredictionItem

public struct PredictionItem: DisplayableAsRow, Hashable {

    // MARK: Properties

    public var id: String
    public var title: String
    public var subtitle: String?
    public var symbol: SFSymbol
    public var type: PredictionResult

    // MARK: Computed Properties

    public var tintColor: Color {
        .red
    }

    // MARK: Lifecycle

    public init(id: String, title: String, subtitle: String?, symbol: SFSymbol = .pin, type: PredictionResult) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
        self.type = type
    }

    // MARK: Static Functions

    // MARK: - Public

    public static func == (lhs: PredictionItem, rhs: PredictionItem) -> Bool {
        return lhs.id == rhs.id
    }

    // MARK: Functions

    public func resolve(in provider: ApplePOI, baseURL: String) async throws -> [AnyDisplayableAsRow] {
        guard case let .apple(completion) = self.type else { return [] }

        let resolved = try await provider.lookup(id: self.id, prediction: completion, baseURL: baseURL)
        let mapped = resolved.map {
            AnyDisplayableAsRow($0)
        }
        return mapped
    }

    public func resolve(in provider: HudHudPOI, baseURL: String) async throws -> [AnyDisplayableAsRow] {
        guard case .hudhud = self.type else { return [] }

        let resolved = try await provider.lookup(id: self.id, prediction: self, baseURL: baseURL)

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

public struct ResolvedItem: DisplayableAsRow, Codable, Hashable, CustomStringConvertible {

    // MARK: Properties

    public var id: String
    public var title: String
    public var subtitle: String?
    public var symbol: SFSymbol
    public var systemColor: SystemColor
    public var category: String?
    public let type: PredictionResult
    public var coordinate: CLLocationCoordinate2D
    public var phone: String?
    public var website: URL?
    public var rating: Double?
    public var ratingsCount: Int?
    public var isOpen: Bool?
    public var trendingImage: String?
    public var mediaURLs: [URL]
    public let distance: Double?
    public let duration: Double?
    public let priceRange: Int?

    // MARK: Computed Properties

    public var description: String {
        return "\(self.title), \(self.subtitle ?? ""), coordinate: \(self.coordinate)"
    }

    public var color: Color {
        self.systemColor.swiftUIColor
    }

    // MARK: Lifecycle

    public init(id: String, title: String, subtitle: String?, category: String? = nil, symbol: SFSymbol = .pin, type: PredictionResult, coordinate: CLLocationCoordinate2D, color: SystemColor = .systemRed, phone: String? = nil, website: URL? = nil, rating: Double? = nil, ratingsCount: Int? = nil, isOpen: Bool? = nil, trendingImage: String? = nil, mediaURLs: [URL] = [], distance: Double? = nil, duration: Double? = nil, priceRange: Int? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.category = category
        self.symbol = symbol
        self.type = type
        self.coordinate = coordinate
        self.phone = phone
        self.website = website
        self.rating = rating
        self.ratingsCount = ratingsCount
        self.isOpen = isOpen
        self.trendingImage = trendingImage
        self.mediaURLs = mediaURLs
        self.systemColor = color
        self.distance = distance
        self.duration = duration
        self.priceRange = priceRange
    }

    // MARK: Functions

    // MARK: - Public

    public func resolve(in _: ApplePOI, baseURL _: String) async throws -> [AnyDisplayableAsRow] {
        return [AnyDisplayableAsRow(self)]
    }

    public func resolve(in _: HudHudPOI, baseURL _: String) async throws -> [AnyDisplayableAsRow] {
        return [AnyDisplayableAsRow(self)]
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
        hasher.combine(self.title)
        hasher.combine(self.subtitle)
    }
}

// MARK: - SFSymbol + Codable

extension SFSymbol: Codable {}

public extension PredictionItem {

    static let ketchup = PredictionItem(id: UUID().uuidString,
                                        title: "Ketch up",
                                        subtitle: "Bluewaters Island - off Jumeirah Beach Residence",
                                        symbol: .pin,
                                        type: .appleResolved)
    static let starbucks = PredictionItem(id: UUID().uuidString,
                                          title: "Starbucks",
                                          subtitle: "The Beach",
                                          symbol: .pin,
                                          type: .appleResolved)
    static let publicPlace = PredictionItem(id: UUID().uuidString,
                                            title: "publicPlace",
                                            subtitle: "Garden - Alyasmen - Riyadh",
                                            symbol: .pin,
                                            type: .appleResolved)
    static let artwork = PredictionItem(id: UUID().uuidString,
                                        title: "Artwork",
                                        subtitle: "artwork - Al-Olya - Riyadh",
                                        symbol: .pin,
                                        type: .appleResolved)
    static let pharmacy = PredictionItem(id: UUID().uuidString,
                                         title: "Pharmacy",
                                         subtitle: "Al-Olya - Riyadh",
                                         symbol: .pin,
                                         type: .appleResolved)
    static let supermarket = PredictionItem(id: UUID().uuidString,
                                            title: "Supermarket",
                                            subtitle: "Al-Narjs - Riyadh",
                                            symbol: .pin,
                                            type: .appleResolved)
}

public extension ResolvedItem {

    static let ketchup = ResolvedItem(id: UUID().uuidString,
                                      title: "Ketch up",
                                      subtitle: "Bluewaters Island - off Jumeirah Beach Residence",
                                      category: "Restaurant",
                                      type: .hudhud,
                                      coordinate: CLLocationCoordinate2D(latitude: 24.723583614203136, longitude: 46.633232873031076),
                                      phone: "0503539560",
                                      website: URL(string: "https://hudhud.sa"),
                                      rating: 4,
                                      ratingsCount: 56,
                                      mediaURLs: .previewMediaURLs)

    static let starbucks = ResolvedItem(id: UUID().uuidString,
                                        title: "Starbucks",
                                        subtitle: "The Beach",
                                        type: .hudhud,
                                        coordinate: CLLocationCoordinate2D(latitude: 24.732211928084162, longitude: 46.87863163915118),
                                        phone: "0503539560",
                                        website: URL(string: "https://hudhud.sa"),
                                        mediaURLs: .previewMediaURLs)

    static let publicPlace = ResolvedItem(id: UUID().uuidString,
                                          title: "publicPlace",
                                          subtitle: "Garden - Alyasmen - Riyadh",
                                          type: .hudhud,
                                          coordinate: CLLocationCoordinate2D(latitude: 24.595375923107532, longitude: 46.598253176098346),
                                          mediaURLs: .previewMediaURLs)

    static let artwork = ResolvedItem(id: UUID().uuidString,
                                      title: "Artwork",
                                      subtitle: "artwork - Al-Olya - Riyadh",
                                      type: .hudhud,
                                      coordinate: CLLocationCoordinate2D(latitude: 24.77888564128478, longitude: 46.61555160031425),
                                      phone: "0503539560",
                                      website: URL(string: "https://hudhud.sa"),
                                      mediaURLs: .previewMediaURLs)

    static let pharmacy = ResolvedItem(id: UUID().uuidString,
                                       title: "Pharmacy",
                                       subtitle: "Al-Olya - Riyadh",
                                       type: .hudhud,
                                       coordinate: CLLocationCoordinate2D(latitude: 24.78796199972764, longitude: 46.69371856758005),
                                       phone: "0503539560",
                                       website: URL(string: "https://hudhud.sa"),
                                       mediaURLs: .previewMediaURLs)

    static let supermarket = ResolvedItem(id: UUID().uuidString,
                                          title: "Supermarket",
                                          subtitle: "Al-Narjs - Riyadh",
                                          type: .hudhud,
                                          coordinate: CLLocationCoordinate2D(latitude: 24.79671388339593, longitude: 46.70810150540095),
                                          phone: "0503539560",
                                          website: URL(string: "https://hudhud.sa"),
                                          mediaURLs: .previewMediaURLs)

    static let coffeeAddressRiyadh = ResolvedItem(id: UUID().uuidString,
                                                  title: "Coffee Address, Riyadh",
                                                  subtitle: "Coffee Shop",
                                                  type: .hudhud,
                                                  coordinate: CLLocationCoordinate2D(latitude: 24.7076060, longitude: 46.6273354))

    static let theGarageRiyadh = ResolvedItem(id: UUID().uuidString,
                                              title: "The Garage, Riyadh",
                                              subtitle: "Work",
                                              type: .hudhud,
                                              coordinate: CLLocationCoordinate2D(latitude: 24.7192284, longitude: 46.6468331))
}

public extension DisplayableRow {

    static let ketchup: DisplayableRow = .resolvedItem(ResolvedItem.ketchup)
    static let starbucks: DisplayableRow = .resolvedItem(ResolvedItem.starbucks)
    static let publicPlace: DisplayableRow = .resolvedItem(ResolvedItem.publicPlace)
    static let artwork: DisplayableRow = .resolvedItem(ResolvedItem.artwork)
    static let pharmacy: DisplayableRow = .resolvedItem(ResolvedItem.pharmacy)
    static let supermarket: DisplayableRow = .resolvedItem(ResolvedItem.supermarket)
}

/*
 public extension POI {

 	var tintColor: Color {
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

public extension [URL] {
    static let previewMediaURLs: Self = [
        // swiftlint:disable:next force_unwrapping
        URL(string: "https://img.freepik.com/free-photo/delicious-arabic-fast-food-skewers-black-plate_23-2148651145.jpg?w=740&t=st=1708506411~exp=1708507011~hmac=e3381fe61b2794e614de83c3f559ba6b712fd8d26941c6b49471d500818c9a77")!,
        // swiftlint:disable:next force_unwrapping
        URL(string: "https://img.freepik.com/free-photo/seafood-sushi-dish-with-details-simple-black-background_23-2151349421.jpg?t=st=1720950213~exp=1720953813~hmac=f62de410f692c7d4b775f8314723f42038aab9b54498e588739272b9879b4895&w=826")!,
        // swiftlint:disable:next force_unwrapping
        URL(string: "https://img.freepik.com/free-photo/side-view-pide-with-ground-meat-cheese-hot-green-pepper-tomato-board_141793-5054.jpg?w=1380&t=st=1708506625~exp=1708507225~hmac=58a53cfdbb7f984c47750f046cbc91e3f90facb67e662c8da4974fe876338cb3")!
    ]
}
