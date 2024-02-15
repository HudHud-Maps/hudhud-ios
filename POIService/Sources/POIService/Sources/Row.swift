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

	public struct Completion: Hashable {
		public let completion: MKLocalSearchCompletion
		public let mapItem: MKMapItem?
	}

	public enum Provider: Hashable {
		case appleCompletion(completion: Completion)
		case appleMapItem(mapItem: MKMapItem)
		case toursprung(poi: POI)
	}
	public let data: Provider

	// MARK: - Init

	public init(mapItem: MKMapItem) {
		self.data = .appleMapItem(mapItem: mapItem)
	}

	public init(appleCompletion: MKLocalSearchCompletion) {
		let mapItem = appleCompletion.value(forKey: "mapItem") as? MKMapItem

		self.data = .appleCompletion(completion: .init(completion: appleCompletion, mapItem: mapItem))
	}

	public init(toursprung: POI) {
		self.data = .toursprung(poi: toursprung)
	}

	// MARK: - Row

	public var title: String {
		switch self.data {
		case .appleCompletion(let completion):
			return completion.completion.title
		case .appleMapItem(let mapItem):
			return mapItem.name ?? "Unknown"
		case .toursprung(let poi):
			return poi.name
		}
	}

	public var subtitle: String {
		switch self.data {
		case .appleCompletion(let completion):
			return completion.completion.subtitle
		case .appleMapItem(let mapItem):
			return mapItem.placemark.formattedAddress ?? ""
		case .toursprung(let poi):
			return poi.subtitle
		}
	}

	public var icon: Image {
		switch self.data {
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
		case .appleCompletion(let completion):
			return completion.mapItem?.icon ?? Image(systemSymbol: .magnifyingglass)
		}
	}

	public var coordinate: CLLocationCoordinate2D? {
		switch self.data {
		case .appleMapItem(let mapItem):
			return mapItem.placemark.coordinate
		case .appleCompletion(let completion):
			return completion.mapItem?.placemark.coordinate
		case .toursprung(let poi):
			return poi.locationCoordinate
		}
	}

	public var poi: POI? {
		switch self.data {
		case .appleCompletion(let completion):
			guard let coordinate = completion.mapItem?.placemark.coordinate else { return nil }

			return POI(name: self.title,
					   subtitle: self.subtitle,
					   locationCoordinate: coordinate,
					   type: "")
		case .appleMapItem(let mapItem):
			return POI(name: self.title,
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
