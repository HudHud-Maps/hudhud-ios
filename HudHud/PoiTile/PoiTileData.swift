//
//  poiTileData.swift
//  HudHud
//
//  Created by Fatima Aljaber on 21/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import CoreLocation
struct PoiTileData: Identifiable {
	let id = UUID()
	let title: String
	let imageUrl: URL?
	let poiType: String
	let locationDistance: CLLocationDistance?
	let rating: String?
	let followersNumbers: String?
	let isFollowed: Bool
	let pricing: Pricing?
	init(title: String, imageUrl: URL?, poiType: String, locationDistance: CLLocationDistance?, rating: String?, followersNumbers: String?, isFollowed: Bool, pricing: Pricing?) {
		self.title = title
		self.imageUrl = imageUrl
		self.poiType = poiType
		self.locationDistance = locationDistance
		self.rating = rating
		self.followersNumbers = followersNumbers
		self.isFollowed = isFollowed
		self.pricing = pricing
	}
	enum Pricing: String {
		case high = "$$$"
		case medium = "$$"
		case low = "$"
	}
	func grtDistanceString() -> String {
		let distanceFormatter = MeasurementFormatter()
		distanceFormatter.unitOptions = .providedUnit
		let measurement = Measurement(value: self.locationDistance?.magnitude.rounded() ?? 0.0, unit: UnitLength.kilometers)
		return distanceFormatter.string(from: measurement)
	}
}
