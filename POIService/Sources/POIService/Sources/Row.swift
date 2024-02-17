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

public struct Row: Hashable {

	public enum Provider: Hashable {
		case appleCompletion(completion: MKLocalSearchCompletion)
		case appleMapItem(mapItem: MKMapItem)
		case toursprung(poi: POI)
	}
	public let provider: Provider

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

	// MARK: - Row

	public var title: String {
		switch self.provider {
		case .appleCompletion(let completion):
			return completion.title
		case .appleMapItem(let mapItem):
			return mapItem.name ?? "Unknown"
		case .toursprung(let poi):
			return poi.title
		}
	}

	public var subtitle: String {
		switch self.provider {
		case .appleCompletion(let completion):
			return completion.subtitle
		case .appleMapItem(let mapItem):
			return mapItem.placemark.formattedAddress ?? ""
		case .toursprung(let poi):
			return poi.subtitle
		}
	}

	public var icon: Image {
		switch self.provider {
		case .toursprung(let poi):
			switch poi.type.lowercased() {
			case "cafe":
				return Image(systemSymbol: .cupAndSaucerFill)
			case "restaurant":
				return Image(systemSymbol: .forkKnife)
			default:
				return Image(systemSymbol: .mappin)
			}
		case .appleMapItem(let mapItem):
			return mapItem.icon
		case .appleCompletion:
			return Image(systemSymbol: .magnifyingglass)
		}
	}

	public var coordinate: CLLocationCoordinate2D? {
		switch self.provider {
		case .appleMapItem(let mapItem):
			return mapItem.placemark.coordinate
		case .appleCompletion:
			return nil
		case .toursprung(let poi):
			return poi.locationCoordinate
		}
	}

	public var poi: POI? {
		switch self.provider {
		case .appleCompletion:
			return nil
		case .appleMapItem(let mapItem):
			return POI(title: self.title,
					   subtitle: self.subtitle,
					   locationCoordinate: mapItem.placemark.coordinate,
					   type: "")
		case .toursprung(let poi):
			return poi
		}
	}
}

extension MKMapItem {

	var icon: Image {
		switch self.pointOfInterestCategory {
		case .some(.airport):
			return Image(systemSymbol: .airplane)
//			case .some(.amusementPark):
//				return Image(systemSymbol: .airplane)
		case .some(.aquarium):
			return Image(systemSymbol: .figureOpenWaterSwim)
		case .some(.atm):
			return Image(systemSymbol: .creditcard)
//			case .some(.bakery):
//				return Image(systemSymbol: .figureOpenWaterSwim)
		case .some(.bank):
			return Image(systemSymbol: .buildingColumns)
//			case .some(.beach):
//				return Image(systemSymbol: .figureOpenWaterSwim)
//			case .some(.brewery):
//				return Image(systemSymbol: .figureOpenWaterSwim)
//			case .some(.cafe):
//				return Image(systemSymbol: .figureOpenWaterSwim)
//			case .some(.campground):
//				return Image(systemSymbol: .figureOpenWaterSwim)
//			case .some(.carRental):
//				return Image(systemSymbol: .figureOpenWaterSwim)
//			case .some(.evCharger):
//				return Image(systemSymbol: .figureOpenWaterSwim)
//			case .some(.fireStation):
//				return Image(systemSymbol: .figureOpenWaterSwim)
//			case .some(.fitnessCenter):
//				return Image(systemSymbol: .figureOpenWaterSwim)
//			case .some(.foodMarket):
//				return Image(systemSymbol: .figureOpenWaterSwim)
//			case .some(.gasStation):
//				return Image(systemSymbol: .figureOpenWaterSwim)
//			case .some(.hospital):
//				return Image(systemSymbol: .figureOpenWaterSwim)
//			case .some(.hotel):
//				return Image(systemSymbol: .figureOpenWaterSwim)
//			case .some(.laundry):
//				return Image(systemSymbol: .figureOpenWaterSwim)
//			case .some(.library):
//				return Image(systemSymbol: .figureOpenWaterSwim)
//			case .some(.marina):
//				return Image(systemSymbol: .figureOpenWaterSwim)
//			case .some(.movieTheater):
//				return Image(systemSymbol: .figureOpenWaterSwim)
//			case .some(.museum):
//				return Image(systemSymbol: .figureOpenWaterSwim)
//			case .some(.nationalPark):
//				return Image(systemSymbol: .figureOpenWaterSwim)
//			case .some(.nightlife):
//				return Image(systemSymbol: .figureOpenWaterSwim)
		case .some(.park):
			if #available(iOS 16.1, *) {
				return Image(systemSymbol: .tree)
			} else {
				return Image(systemSymbol: .mappin)
			}
		case .some(.parking):
			return Image(systemSymbol: .pCircleFill)
//			case .some(.pharmacy):
//				return Image(systemSymbol: .figureOpenWaterSwim)
//			case .some(.police):
//				return Image(systemSymbol: .figureOpenWaterSwim)
//			case .some(.postOffice):
//				return Image(systemSymbol: .figureOpenWaterSwim)
//			case .some(.publicTransport):
//				return Image(systemSymbol: .figureOpenWaterSwim)
//			case .some(.restaurant):
//				return Image(systemSymbol: .figureOpenWaterSwim)
//			case .some(.restroom):
//				return Image(systemSymbol: .figureOpenWaterSwim)
//			case .some(.school):
//				return Image(systemSymbol: .figureOpenWaterSwim)
//			case .some(.stadium):
//				return Image(systemSymbol: .figureOpenWaterSwim)
//			case .some(.store):
//				return Image(systemSymbol: .figureOpenWaterSwim)
//			case .some(.theater):
//				return Image(systemSymbol: .figureOpenWaterSwim)
//			case .some(.university):
//				return Image(systemSymbol: .figureOpenWaterSwim)
//			case .some(.winery):
//				return Image(systemSymbol: .figureOpenWaterSwim)
//			case .some(.zoo):
//				return Image(systemSymbol: .figureOpenWaterSwim)

		default:
			return Image(systemSymbol: .mappin)
		}
	}
}

extension MKPlacemark {
	var formattedAddress: String? {
		guard let postalAddress = postalAddress else { return nil }
		return CNPostalAddressFormatter.string(from: postalAddress, style: .mailingAddress).replacingOccurrences(of: "\n", with: " ")
	}
}
