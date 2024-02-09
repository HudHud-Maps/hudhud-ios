//
//  POIService.swift
//  POIService
//
//  Created by Patrick Kladek on 01.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import CoreLocation
import SwiftUI

public protocol POIServiceProtocol {

    static var serviceName: String { get }

    func search(term: String) async throws -> [POI]
}

public struct POI: Identifiable {

    public var id: Int
    public var name: String
	public var subtitle: String
    public var locationCoordinate: CLLocationCoordinate2D
    public var type: String

	public init(id: Int = .random(in: 0...1000000), name: String, subtitle: String, locationCoordinate: CLLocationCoordinate2D, type: String) {
		self.id = id
        self.name = name
		self.subtitle = subtitle
        self.locationCoordinate = locationCoordinate
        self.type = type
    }
}

public extension POI {

	public var icon: Image {
		switch self.type.lowercased() {
		case "cafe":
			return Image(systemName: "cup.and.saucer.fill")
		case "restaurant":
			return Image(systemName: "fork.knife")
		default:
			return Image(systemName: "mappin")
		}
	}
}

public extension POI {
	public static let ketchup = POI(name: "Ketch up - Dubai",
									subtitle: "Bluewaters Island - off Jumeirah Beach Residence - Bluewaters Island - Dubai",
									locationCoordinate: CLLocationCoordinate2D(latitude: 25.077744998955207, longitude: 55.124647403691284),
									type: "Restaurant")
	public static let starbucks = POI(name: "Starbucks",
									  subtitle: "The Beach - Jumeirah Beach Residence - Dubai",
									locationCoordinate: CLLocationCoordinate2D(latitude: 25.075671955460354, longitude: 55.13046336047564),
									type: "Cafe")
}
