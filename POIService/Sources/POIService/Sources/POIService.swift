//
//  POIService.swift
//  POIService
//
//  Created by Patrick Kladek on 01.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation
import SFSafeSymbols
import SwiftUI
import MapKit

public protocol POIServiceProtocol: ObservableObject {

	static var serviceName: String { get }
	func lookup(prediction: PredictionResult) async throws -> [Row]
	func predict(term: String) async throws -> [Row]
}

public enum PredictionResult: Hashable {
	case apple(completion: MKLocalSearchCompletion)
	case toursprung(result: Row)
}

public class POI: Hashable, Identifiable {

	public static func == (lhs: POI, rhs: POI) -> Bool {
		return lhs.title == rhs.title && lhs.subtitle == rhs.subtitle
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(title)
		hasher.combine(subtitle)
	}

	public var id: Int
	public var title: String
	public var subtitle: String
	public var locationCoordinate: CLLocationCoordinate2D
	public var type: String
	public var userInfo: [String: AnyHashable] = [:]

	public init(id: Int = .random(in: 0...1000000), title: String, subtitle: String, locationCoordinate: CLLocationCoordinate2D, type: String) {
		self.id = id
		self.title = title
		self.subtitle = subtitle
		self.locationCoordinate = locationCoordinate
		self.type = type
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
}
