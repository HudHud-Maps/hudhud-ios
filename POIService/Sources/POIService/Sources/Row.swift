//
//  Row.swift
//  POIService
//
//  Created by Patrick Kladek on 15.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import MapKit

public struct Row {

	public var searchCompletion: MKLocalSearchCompletion? {
		didSet {
			guard let mapItem = self.searchCompletion?.value(forKey: "mapItem") as? MKMapItem else { return }

			self.mapItem = mapItem
		}
	}
	public var mapItem: MKMapItem?

	let title: String
	let subtitle: String

	// MARK: - Init

	public init(searchCompletion: MKLocalSearchCompletion) {
		self.searchCompletion = searchCompletion
		self.title = searchCompletion.title
		self.subtitle = searchCompletion.subtitle
	}

	public init(mapItem: MKMapItem) {
		self.mapItem = mapItem
		self.title = mapItem.name ?? "Unknown"
		self.subtitle = mapItem.description
	}
}
