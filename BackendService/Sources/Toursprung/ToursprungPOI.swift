//
//  ToursprungPOI.swift
//  ToursprungPOI
//
//  Created by Patrick Kladek on 01.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation
import MapKit
import SFSafeSymbols
import SwiftUI

// MARK: - ToursprungPOI

public actor ToursprungPOI: POIServiceProtocol {

    enum GeocoderError: Error, LocalizedError {
        case buildingURL
        case decodingError

        var errorDescription: String? {
            switch self {
            case .buildingURL:
                "Can't transform Input into URL."
            case .decodingError:
                "HudHud responded with invalid format."
            }
        }
    }

    private let session: URLSession

    // MARK: - POIServiceProtocol

    public static var serviceName: String = "Apple"

    // MARK: - Lifecycle

    public init() {
        self.session = .shared
    }

    // MARK: - Public

    public func predict(term: String, coordinates: CLLocationCoordinate2D?) async throws -> [AnyDisplayableAsRow] {
        
        try await Task.sleep(nanoseconds: 190 * NSEC_PER_MSEC) // debouncer
        try Task.checkCancellation()
        
        let results =  try await self.search(term: term)
        
        return results.map { item in
            return AnyDisplayableAsRow(item)
        }
    }

    public func lookup(id _: String, prediction _: Any) async throws -> [ResolvedItem] {
        return []
    }
    
}

// MARK: - Private

private extension ToursprungPOI {

    func search(term: String) async throws -> [ResolvedItem] {
        // "https://geocoder.maptoolkit.net/search?<params>"

        var components = URLComponents()
        components.scheme = "https"
        components.host = "geocoder.maptoolkit.net"
        components.path = "/search"
        components.queryItems = [
            URLQueryItem(name: "q", value: term),
            URLQueryItem(name: "countrycodes", value: "sa,at"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "limit", value: "50"),
            URLQueryItem(name: "api_key", value: "hudhud")
        ]
        guard let url = components.url else {
            throw GeocoderError.buildingURL
        }

        let request = URLRequest(url: url)
        guard let (data, response) = try await self.session.data(for: request) as? (Data, HTTPURLResponse) else {
            throw GeocoderError.decodingError
        }
        guard response.statusCode == 200 else {
            // parse error response
            throw GeocoderError.decodingError
        }

        let decoder = JSONDecoder()
        let poiElements = try decoder.decode([POIElement].self, from: data)
        let items: [ResolvedItem] = poiElements.compactMap {
            guard let lat = Double($0.lat),
                  let lon = Double($0.lon) else { return nil }

            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)

            let symbol = self.symbol(from: $0.type)
            var item = ResolvedItem(id: "\($0.placeID)", title: $0.displayName, subtitle: $0.address.description, category: $0.type.lowercased(), symbol: symbol, type: .toursprung, coordinate: coordinate)

            let mirror = Mirror(reflecting: $0)
            mirror.children.forEach { child in
                guard let label = child.label else { return }

                item.userInfo[label] = child.value as? AnyHashable
            }

            return item
        }
        return items
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

private extension ToursprungPOI {

    func symbol(from: String) -> SFSymbol {
        switch from.lowercased() {
        case "cafe":
            return .cupAndSaucerFill
        case "accomodation", "appartment", "camp_site", "caravan_site", "chalet", "guest_house", "hostel", "hotel", "motel", "wilderness_hut":
            return .houseFill
        case "alpine_hut":
            return .tramFill

        // Animals
        case "animal_boarding", "animal_shelter", "veterinary":
            return .pawprintFill

        // Arts and Culture
        case "arts_centre", "gallery", "museum":
            return .paintpaletteFill
        case "library":
            return .booksVerticalFill
        case "place_of_worship":
            return .buildingColumnsFill
        case "studio":
            return .cameraFill

        // Education
        case "college", "kindergarten", "language_school", "music_school", "school", "university":
            return .graduationcapFill
        case "driving_school":
            return .carFill

        // Facilities
        case "bench", "shelter", "table", "toilets":
            return .rectangleFillOnRectangleAngledFill
        case "clock", "post_box", "telephone":
            return .clockFill
        case "drinking_water", "water_point":
            return .dropFill
        case "fountain":
            return .dropCircleFill
        case "recycling", "recycling_station", "waste_basket", "waste_disposal":
            return .trashFill
        case "shower":
            return .showerFill

        // Financial
        case "atm":
            return .creditcardFill
        case "bank", "bureau_de_change":
            return .buildingFill

        // Healthcare
        case "baby_hatch", "clinic", "dentist", "doctors", "hospital", "nursing_home", "retirement_home", "social_facility":
            return .crossFill

        // Leisure and Entertainment
        case "amusement_arcade", "adult_gaming_centre", "cinema", "nightclub", "theme_park", "zoo":
            return .filmFill
        case "beach_resort", "park", "picnic_site", "playground":
            return .leafFill
        case "dog_park":
            return .pawprintFill
        case "swimming_pool", "water_park":
            return .waveformPathEcgRectangleFill

        // Tourism
        case "aquarium", "artwork", "attraction", "viewpoint":
            return .eyeglasses
        case "information":
            return .infoCircleFill

        // Shop
        case "bakery", "beverages", "butcher", "cheese", "chocolate", "coffee", "confectionery", "dairy", "deli", "farm", "fish", "greengrocer", "tea":
            return .cartFill
        case "bicycle", "bicycle_parking", "bicycle_rental", "bicycle_repair_station":
            return .bicycle
        case "book", "books":
            return .bookFill
        case "clothes", "fashion":
            return .tshirtFill
        case "convenience", "supermarket":
            return .bagFill
        case "pharmacy":
            return .pillFill

        // Food & Drink
        case "bar", "biergarten", "fast_food", "food_court", "ice_cream", "pub", "restaurant":
            return .forkKnife

        // Transport
        case "boat_sharing", "bus_station", "bus_stop", "car_rental", "car_repair", "car_sharing", "car_wash", "charging_station", "ev_charging", "ferry_terminal", "fuel", "motorcycle_parking", "parking", "parking_entrance", "parking_space", "taxi":
            return .carFill

        default:
            return .mappin
        }
    }
}
