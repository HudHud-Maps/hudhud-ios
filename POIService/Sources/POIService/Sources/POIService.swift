//
//  POIService.swift
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
	func lookup(prediction: Any) async throws -> [ResolvedItem]
	func predict(term: String) async throws -> [AnyDisplayableAsRow]
}

// MARK: - PredictionResult

public enum PredictionResult: Hashable, Codable {
	case apple(completion: MKLocalSearchCompletion)
	case appleResolved
	case toursprung

	enum CodingKeys: CodingKey {
		case appleResolved
		case toursprung
	}
}

// MARK: - DisplayableAsRow

public protocol DisplayableAsRow: Identifiable {
	var id: String { get }
	var title: String { get }
	var subtitle: String { get }
	var icon: Image { get }

	var onTap: (() -> Void)? { get }
	func resolve(in provider: ApplePOI) async throws -> [AnyDisplayableAsRow]
}

// MARK: - AnyDisplayableAsRow

public struct AnyDisplayableAsRow: DisplayableAsRow {

	public var title: String {
		self.innerModel.title
	}

	public var subtitle: String {
		self.innerModel.subtitle
	}

	public var icon: Image {
		self.innerModel.icon
	}

	public var onTap: (() -> Void)? {
		self.innerModel.onTap
	}

	public var innerModel: any DisplayableAsRow

	public var id: String { self.innerModel.id }

	// MARK: - Lifecycle

	public init(_ model: some DisplayableAsRow) {
		self.innerModel = model // Automatically casts to “any” type
	}

	// MARK: - Public

	public static func == (lhs: AnyDisplayableAsRow, rhs: AnyDisplayableAsRow) -> Bool {
		return lhs.id == rhs.id
	}

	public func resolve(in provider: ApplePOI) async throws -> [AnyDisplayableAsRow] {
		return try await self.innerModel.resolve(in: provider)
	}

}

// MARK: - PredictionItem

public struct PredictionItem: DisplayableAsRow {

	public var id: String
	public var title: String
	public var subtitle: String
	public var icon: Image
	public var type: PredictionResult
	public var onTap: (() -> Void)?

	// MARK: - Lifecycle

	public init(id: String, title: String, subtitle: String, icon: Image, type: PredictionResult, onTap: (() -> Void)? = nil) {
		self.id = id
		self.title = title
		self.subtitle = subtitle
		self.icon = icon
		self.type = type
		self.onTap = onTap
	}

	// MARK: - Public

	public static func == (lhs: PredictionItem, rhs: PredictionItem) -> Bool {
		return lhs.id == rhs.id
	}

	public func resolve(in provider: ApplePOI) async throws -> [AnyDisplayableAsRow] {
		guard case let .apple(completion) = self.type else { return [] }

		let resolved = try await provider.lookup(prediction: completion)
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

public struct ResolvedItem: DisplayableAsRow, Codable, Equatable, Hashable, CustomStringConvertible {
	public var id: String
	public var title: String
	public var subtitle: String
	public var icon: Image {
		return Image(systemSymbol: .pinFill)
	}

	public let type: PredictionResult
	public var coordinate: CLLocationCoordinate2D
	public var onTap: (() -> Void)?

	public var userInfo: [String: AnyHashable] = [:]

	enum CodingKeys: String, CodingKey {
		case id, title, subtitle, type, coordinate
	}

	public var description: String {
		return "\(self.title), \(self.subtitle), coordinate: \(self.coordinate)"
	}

	// MARK: - Lifecycle

	public init(id: String, title: String, subtitle: String, type: PredictionResult, coordinate: CLLocationCoordinate2D, onTap: (() -> Void)? = nil) {
		self.id = id
		self.title = title
		self.subtitle = subtitle
		self.type = type
		self.coordinate = coordinate
		self.onTap = onTap
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.id = try container.decode(String.self, forKey: .id)
		self.title = try container.decode(String.self, forKey: .title)
		self.subtitle = try container.decode(String.self, forKey: .subtitle)
		self.type = try container.decode(PredictionResult.self, forKey: .type)
		self.coordinate = try container.decode(CLLocationCoordinate2D.self, forKey: .coordinate)
	}

	// MARK: - Public

	public static func == (lhs: ResolvedItem, rhs: ResolvedItem) -> Bool {
		return lhs.id == rhs.id
	}

	public func resolve(in _: ApplePOI) async throws -> [AnyDisplayableAsRow] {
		return [AnyDisplayableAsRow(self)]
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.id, forKey: .id)
		try container.encode(self.title, forKey: .title)
		try container.encode(self.subtitle, forKey: .subtitle)
		try container.encode(self.coordinate, forKey: .coordinate)
		try container.encode(self.type, forKey: .type)
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(self.id)
		hasher.combine(self.title)
		hasher.combine(self.subtitle)
	}
}

public extension PredictionItem {

	static let ketchup = PredictionItem(id: UUID().uuidString,
										title: "Bluewaters Island - off Jumeirah Beach Residence",
										subtitle: "Bluewaters Island - off Jumeirah Beach Residence",
										icon: .init(systemSymbol: .pin),
										type: .appleResolved)
	static let starbucks = PredictionItem(id: UUID().uuidString,
										  title: "Starbucks",
										  subtitle: "The Beach",
										  icon: .init(systemSymbol: .pin),
										  type: .appleResolved)
	static let publicPlace = PredictionItem(id: UUID().uuidString,
											title: "publicPlace",
											subtitle: "Garden - Alyasmen - Riyadh",
											icon: .init(systemSymbol: .pin),
											type: .appleResolved)
	static let artwork = PredictionItem(id: UUID().uuidString,
										title: "Artwork",
										subtitle: "artwork - Al-Olya - Riyadh",
										icon: .init(systemSymbol: .pin),
										type: .appleResolved)
	static let pharmacy = PredictionItem(id: UUID().uuidString,
										 title: "Pharmacy",
										 subtitle: "Al-Olya - Riyadh",
										 icon: .init(systemSymbol: .pin),
										 type: .appleResolved)
	static let supermarket = PredictionItem(id: UUID().uuidString,
											title: "Supermarket",
											subtitle: "Al-Narjs - Riyadh",
											icon: .init(systemSymbol: .pin),
											type: .appleResolved)
}

public extension ResolvedItem {

	init?(element: POIElement) {
		guard let lat = Double(element.lat),
			  let lon = Double(element.lon) else { return nil }

		let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)

		self.init(id: "\(element.placeID)",
				  title: element.displayName,
				  subtitle: element.address.description,
				  type: .toursprung,
				  coordinate: coordinate)

		let mirror = Mirror(reflecting: element)
		mirror.children.forEach { child in
			guard let label = child.label else { return }

			self.userInfo[label] = child.value as? AnyHashable
		}
	}
}
