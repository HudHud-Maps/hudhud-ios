//
//  ApplePOI.swift
//  ApplePOI
//
//  Created by Patrick Kladek on 01.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Contacts
import CoreLocation
import Foundation
import MapKit
import POIService
import SwiftUI

// MARK: - ApplePOI

public actor ApplePOI: POIServiceProtocol {

	private var localSearch: MKLocalSearch?
	private var completer: MKLocalSearchCompleter
	private var continuation: CheckedContinuation<[AnyDisplayableAsRow], Error>?
	private let delegate: DelegateWrapper

	// MARK: - POIServiceProtocol

	public static var serviceName: String = "Apple"

	// MARK: - Lifecycle

	public init() {
		self.completer = MKLocalSearchCompleter()
		self.delegate = DelegateWrapper()
		self.delegate.apple = self
		Task {
			await self.completer.delegate = self.delegate
		}
	}

	// MARK: - Public

	public func lookup(prediction: Any) async throws -> [ResolvedItem] {
		guard let completion = prediction as? MKLocalSearchCompletion else {
			return []
		}

		let searchRequest = MKLocalSearch.Request(completion: completion)
		searchRequest.resultTypes = .pointOfInterest

		return try await withCheckedThrowingContinuation { continuation in
			self.localSearch = MKLocalSearch(request: searchRequest)
			self.localSearch?.start { response, error in
				if let error {
					continuation.resume(throwing: error)
					return
				}

				guard let mapItems = response?.mapItems else {
					continuation.resume(returning: [])
					return
				}

				let items = mapItems.compactMap {
					return ResolvedItem(id: UUID().uuidString,
										title: $0.name ?? "",
//								 subtitle: $0.pointOfInterestCategory?.rawValue.localizedUppercase ?? "",
										subtitle: $0.placemark.formattedAddress ?? "",
										coordinate: $0.placemark.coordinate,
										onTap: {
											print(#function)
										})
				}
				continuation.resume(returning: items)
			}
		}
	}

	public func predict(term: String) async throws -> [AnyDisplayableAsRow] {
		return try await withCheckedThrowingContinuation { continuation in
			if let continuation = self.continuation {
				self.completer.cancel()
				continuation.resume(returning: [])
				self.continuation = nil
			}

			if term.isEmpty {
				continuation.resume(returning: [])
				return
			}

			self.continuation = continuation
			DispatchQueue.main.sync {
				self.completer.queryFragment = term
			}
		}
	}

	// MARK: - Internal

	func update(results: [AnyDisplayableAsRow]) async {
		self.continuation?.resume(returning: results)
		self.continuation = nil
	}

	func update(error: Error) async {
		self.continuation?.resume(throwing: error)
		self.continuation = nil
	}
}

// MARK: - DelegateWrapper

private class DelegateWrapper: NSObject, MKLocalSearchCompleterDelegate {

	weak var apple: ApplePOI?

	// MARK: - Internal

	// MARK: - MKLocalSearchCompleterDelegate

	func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
		let results = completer.results.compactMap {
			AnyDisplayableAsRow(PredicatedItem(id: UUID().uuidString,
											   title: $0.title,
											   subtitle: $0.subtitle,
											   icon: .init(systemSymbol: .pin),
											   type: .apple(completion: $0)))
		}
		Task {
			await self.apple?.update(results: results)
		}
	}

	func completer(_: MKLocalSearchCompleter, didFailWithError error: Error) {
		Task {
			await self.apple?.update(error: error)
		}
	}
}

extension MKPlacemark {
	var formattedAddress: String? {
		guard let postalAddress else { return nil }
		return CNPostalAddressFormatter.string(from: postalAddress, style: .mailingAddress).replacingOccurrences(of: "\n", with: " ")
	}
}
