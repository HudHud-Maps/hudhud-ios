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
	public var userInfo: [String: AnyHashable] = [:]

	public init(id: Int = .random(in: 0...1000000), name: String, subtitle: String, locationCoordinate: CLLocationCoordinate2D, type: String) {
		self.id = id
		self.name = name
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

public extension POI {
	static let ketchup = POI(name: "Ketch up - Dubai",
							 subtitle: "Bluewaters Island - off Jumeirah Beach Residence - Bluewaters Island - Dubai",
							 locationCoordinate: CLLocationCoordinate2D(latitude: 25.077744998955207, longitude: 55.124647403691284),
							 type: "Restaurant")
	static let starbucks = POI(name: "Starbucks",
							   subtitle: "The Beach - Jumeirah Beach Residence - Dubai",
							   locationCoordinate: CLLocationCoordinate2D(latitude: 25.075671955460354, longitude: 55.13046336047564),
							   type: "Cafe")
}

public protocol DictionaryConvertable: CustomStringConvertible {
	func dictionary() -> [String: AnyHashable]
}

public extension DictionaryConvertable {

	func dictionary() -> [String: AnyHashable] {
		var dict = [String: AnyHashable]()
		let mirror = Mirror(reflecting: self)
		for child in mirror.children {
			guard let key = child.label else { continue }

			let childMirror = Mirror(reflecting: child.value)
			switch childMirror.displayStyle {
			case .struct, .class:
				if let childDict = (child.value as? DictionaryConvertable)?.dictionary() {
					dict[key] = childDict
				}
			case .collection:
				if let childArray = (child.value as? [DictionaryConvertable])?.compactMap({ $0.dictionary() }) {
					dict[key] = childArray
				}
			case .set:
				if let childArray = (child.value as? Set<AnyHashable>)?.compactMap({ ($0 as? DictionaryConvertable)?.dictionary() }) {
					dict[key] = childArray
				}
			default:
				if let child = child.value as? CustomStringConvertible {
					dict[key] = child.description
				}

				dict[key] = child.value as? AnyHashable
			}
		}

		return dict
	}
}
