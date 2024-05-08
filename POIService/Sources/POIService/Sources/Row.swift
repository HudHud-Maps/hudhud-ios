//
//  Row.swift
//  POIService
//
//  Created by Patrick Kladek on 15.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Contacts
import Foundation
import MapKit
import SwiftUI

// MARK: - Row

public struct Row: Hashable {

	public enum Provider: Hashable {
		case appleCompletion(completion: MKLocalSearchCompletion)
		case appleMapItem(mapItem: MKMapItem)
		case toursprung(poi: POI)
	}

	public let provider: Provider

	// MARK: - Row

	public var title: String {
		switch self.provider {
		case let .appleCompletion(completion):
			return completion.title
		case let .appleMapItem(mapItem):
			return mapItem.name ?? "Unknown"
		case let .toursprung(poi):
			return poi.title
		}
	}

	public var subtitle: String {
		switch self.provider {
		case let .appleCompletion(completion):
			return completion.subtitle
		case let .appleMapItem(mapItem):
			return mapItem.placemark.formattedAddress ?? ""
		case let .toursprung(poi):
			return poi.subtitle
		}
	}

	public var id: String {
		switch self.provider {
		case let .appleCompletion(completion):
			return "\(completion.title)|\(completion.subtitle)"
		case let .appleMapItem(mapItem):
			return "\(self.title)|\(self.subtitle)|\(mapItem.placemark.coordinate.latitude)|\(mapItem.placemark.coordinate.longitude)"
		case let .toursprung(poi):
			return poi.id
		}
	}

	public var icon: Image {
		switch self.provider {
		case let .toursprung(poi):
			switch poi.type.lowercased() {
			case "cafe":
				return Image(systemSymbol: .cupAndSaucerFill)
			case "accomodation", "appartment", "camp_site", "caravan_site", "chalet", "guest_house", "hostel", "hotel", "motel", "wilderness_hut":
				return Image(systemSymbol: .houseFill)
			case "alpine_hut":
				return Image(systemSymbol: .tramFill)
			// Animals
			case "animal_boarding", "animal_shelter", "veterinary":
				return Image(systemSymbol: .pawprintFill)
			// Arts and Culture
			case "arts_centre", "gallery", "museum":
				return Image(systemSymbol: .paintpaletteFill)
			case "library":
				return Image(systemSymbol: .booksVerticalFill)
			case "place_of_worship":
				return Image(systemSymbol: .buildingColumnsFill)
			case "studio":
				return Image(systemSymbol: .cameraFill)
			// Education
			case "college", "kindergarten", "language_school", "music_school", "school", "university":
				return Image(systemSymbol: .graduationcapFill)
			case "driving_school":
				return Image(systemSymbol: .carFill)

			// Facilities
			case "bench", "shelter", "table", "toilets":
				return Image(systemSymbol: .rectangleFillOnRectangleAngledFill)
			case "clock", "post_box", "telephone":
				return Image(systemSymbol: .clockFill)
			case "drinking_water", "water_point":
				return Image(systemSymbol: .dropFill)
			case "fountain":
				return Image(systemSymbol: .dropCircleFill)
			case "recycling", "recycling_station", "waste_basket", "waste_disposal":
				return Image(systemSymbol: .trashFill)
			case "shower":
				return Image(systemSymbol: .showerFill)
			// Financial
			case "atm":
				return Image(systemSymbol: .creditcardFill)
			case "bank", "bureau_de_change":
				return Image(systemSymbol: .buildingFill)

			// Healthcare
			case "baby_hatch", "clinic", "dentist", "doctors", "hospital", "nursing_home", "retirement_home", "social_facility":
				return Image(systemSymbol: .crossFill)

			// Leisure and Entertainment
			case "amusement_arcade", "adult_gaming_centre", "cinema", "nightclub", "theme_park", "zoo":
				return Image(systemSymbol: .filmFill)
			case "beach_resort", "park", "picnic_site", "playground":
				return Image(systemSymbol: .leafFill)
			case "dog_park":
				return Image(systemSymbol: .pawprintFill)
			case "swimming_pool", "water_park":
				return Image(systemSymbol: .waveformPathEcgRectangleFill)
			// Tourism
			case "aquarium", "artwork", "attraction", "viewpoint":
				return Image(systemSymbol: .eyeglasses)
			case "information":
				return Image(systemSymbol: .infoCircleFill)

			// Shop
			case "bakery", "beverages", "butcher", "cheese", "chocolate", "coffee", "confectionery", "dairy", "deli", "farm", "fish", "greengrocer", "tea":
				return Image(systemSymbol: .cartFill)
			case "bicycle", "bicycle_parking", "bicycle_rental", "bicycle_repair_station":
				return Image(systemSymbol: .bicycle)
			case "book", "books":
				return Image(systemSymbol: .bookFill)
			case "clothes", "fashion":
				return Image(systemSymbol: .tshirtFill)
			case "convenience", "supermarket":
				return Image(systemSymbol: .bagFill)
			case "pharmacy":
				return Image(systemSymbol: .pillFill)
			// Food & Drink
			case "bar", "biergarten", "fast_food", "food_court", "ice_cream", "pub", "restaurant":
				return Image(systemSymbol: .forkKnife)

			// Transport
			case "boat_sharing", "bus_station", "bus_stop", "car_rental", "car_repair", "car_sharing", "car_wash", "charging_station", "ev_charging", "ferry_terminal", "fuel", "motorcycle_parking", "parking", "parking_entrance", "parking_space", "taxi":
				return Image(systemSymbol: .carFill)

			default:
				return Image(systemSymbol: .mappin)
			}
		case let .appleMapItem(mapItem):
			return mapItem.icon
		case let .appleCompletion(completion):
			let icon = completion.subtitle == "Search Nearby" ? Image(systemSymbol: .magnifyingglass) : Image(systemSymbol: .mappin)
			return icon
		}
	}

	public var coordinate: CLLocationCoordinate2D? {
		switch self.provider {
		case let .appleMapItem(mapItem):
			return mapItem.placemark.coordinate
		case .appleCompletion:
			return nil
		case let .toursprung(poi):
			return poi.locationCoordinate
		}
	}

	public var poi: POI? {
		switch self.provider {
		case let .appleCompletion(completion):
			let type = completion.subtitle == "Search Nearby" ? "Search Nearby" : "individual"
			guard let coordinate = self.coordinate else {
				return nil
			}
			return POI(id: self.id, title: self.title,
					   subtitle: self.subtitle,
					   locationCoordinate: coordinate,
					   type: "\(type)",
					   phone: self.poi?.phone ?? "",
					   website: self.poi?.website ?? URL(string: ""))
		case let .appleMapItem(mapItem):
			return POI(id: self.id, title: self.title,
					   subtitle: self.subtitle,
					   locationCoordinate: mapItem.placemark.coordinate,
					   type: "",
					   phone: mapItem.phoneNumber,
					   website: mapItem.url ?? URL(string: ""))
		case let .toursprung(poi):
			return poi
		}
	}

	// MARK: - Lifecycle

	// MARK: - Init

	public init(mapItem: MKMapItem) {
		self.provider = .appleMapItem(mapItem: mapItem)
	}

	public init(appleCompletion: MKLocalSearchCompletion) {
		self.provider = .appleCompletion(completion: appleCompletion)
	}

	public init(toursprung: POI) {
		self.provider = .toursprung(poi: toursprung)
	}

}

extension MKMapItem {

	var icon: Image {
		switch self.pointOfInterestCategory {
		case .some(.airport):
			return Image(systemSymbol: .airplane)
		//            case .some(.amusementPark):
		//                return Image(systemSymbol: .airplane)
		case .some(.aquarium):
			return Image(systemSymbol: .figureOpenWaterSwim)
		case .some(.atm):
			return Image(systemSymbol: .creditcard)
		//            case .some(.bakery):
		//                return Image(systemSymbol: .figureOpenWaterSwim)
		case .some(.bank):
			return Image(systemSymbol: .buildingColumns)
		//            case .some(.beach):
		//                return Image(systemSymbol: .figureOpenWaterSwim)
		//            case .some(.brewery):
		//                return Image(systemSymbol: .figureOpenWaterSwim)
		//            case .some(.cafe):
		//                return Image(systemSymbol: .figureOpenWaterSwim)
		//            case .some(.campground):
		//                return Image(systemSymbol: .figureOpenWaterSwim)
		//            case .some(.carRental):
		//                return Image(systemSymbol: .figureOpenWaterSwim)
		//            case .some(.evCharger):
		//                return Image(systemSymbol: .figureOpenWaterSwim)
		//            case .some(.fireStation):
		//                return Image(systemSymbol: .figureOpenWaterSwim)
		//            case .some(.fitnessCenter):
		//                return Image(systemSymbol: .figureOpenWaterSwim)
		//            case .some(.foodMarket):
		//                return Image(systemSymbol: .figureOpenWaterSwim)
		//            case .some(.gasStation):
		//                return Image(systemSymbol: .figureOpenWaterSwim)
		//            case .some(.hospital):
		//                return Image(systemSymbol: .figureOpenWaterSwim)
		//            case .some(.hotel):
		//                return Image(systemSymbol: .figureOpenWaterSwim)
		//            case .some(.laundry):
		//                return Image(systemSymbol: .figureOpenWaterSwim)
		//            case .some(.library):
		//                return Image(systemSymbol: .figureOpenWaterSwim)
		//            case .some(.marina):
		//                return Image(systemSymbol: .figureOpenWaterSwim)
		//            case .some(.movieTheater):
		//                return Image(systemSymbol: .figureOpenWaterSwim)
		//            case .some(.museum):
		//                return Image(systemSymbol: .figureOpenWaterSwim)
		//            case .some(.nationalPark):
		//                return Image(systemSymbol: .figureOpenWaterSwim)
		//            case .some(.nightlife):
		//                return Image(systemSymbol: .figureOpenWaterSwim)
		case .some(.park):
			if #available(iOS 16.1, *) {
				return Image(systemSymbol: .tree)
			} else {
				return Image(systemSymbol: .mappin)
			}
		case .some(.parking):
			return Image(systemSymbol: .pCircleFill)
//            case .some(.pharmacy):
//                return Image(systemSymbol: .figureOpenWaterSwim)
//            case .some(.police):
//                return Image(systemSymbol: .figureOpenWaterSwim)
//            case .some(.postOffice):
//                return Image(systemSymbol: .figureOpenWaterSwim)
//            case .some(.publicTransport):
//                return Image(systemSymbol: .figureOpenWaterSwim)
//            case .some(.restaurant):
//                return Image(systemSymbol: .figureOpenWaterSwim)
//            case .some(.restroom):
//                return Image(systemSymbol: .figureOpenWaterSwim)
//            case .some(.school):
//                return Image(systemSymbol: .figureOpenWaterSwim)
//            case .some(.stadium):
//                return Image(systemSymbol: .figureOpenWaterSwim)
//            case .some(.store):
//                return Image(systemSymbol: .figureOpenWaterSwim)
//            case .some(.theater):
//                return Image(systemSymbol: .figureOpenWaterSwim)
//            case .some(.university):
//                return Image(systemSymbol: .figureOpenWaterSwim)
//            case .some(.winery):
//                return Image(systemSymbol: .figureOpenWaterSwim)
//            case .some(.zoo):
//                return Image(systemSymbol: .figureOpenWaterSwim)

		default:
			return Image(systemSymbol: .mappin)
		}
	}
}

extension MKPlacemark {
	var formattedAddress: String? {
		guard let postalAddress else { return nil }
		return CNPostalAddressFormatter.string(from: postalAddress, style: .mailingAddress).replacingOccurrences(of: "\n", with: " ")
	}
}
