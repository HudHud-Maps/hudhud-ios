//
//  ApplePOI.swift
//  ApplePOI
//
//  Created by Patrick Kladek on 01.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation
import MapKit
import POIService
import SwiftUI

// MARK: - ApplePOI

public actor ApplePOI: POIServiceProtocol {

	private var localSearch: MKLocalSearch?
	private var completer: MKLocalSearchCompleter
	private var continuation: CheckedContinuation<[POI], Error>?
	private let delegate: DelegateWrapper

	// MARK: - POIServiceProtocol

	public static var serviceName: String = "Apple"

	// MARK: - Lifecycle

	public init() {
		self.completer = MKLocalSearchCompleter()
		self.delegate = DelegateWrapper()
		self.delegate.poi = self
		Task {
			await self.completer.delegate = self.delegate
		}
	}

	// MARK: - Public

	public func lookup(prediction: PredictionResult) async throws -> [POI] {
		guard case let .apple(completion) = prediction else {
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

				let rows = mapItems.compactMap {
					Row(mapItem: $0).poi
				}
				continuation.resume(returning: rows)
			}
		}
	}

	public func predict(term: String) async throws -> [POI] {
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

	func update(results: [POI]) async {
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

	weak var poi: ApplePOI?

	// MARK: - Internal

	// MARK: - MKLocalSearchCompleterDelegate

	func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
		let results = completer.results.compactMap {
			Row(appleCompletion: $0).poi
		}
		Task {
			await self.poi?.update(results: results)
		}
	}

	func completer(_: MKLocalSearchCompleter, didFailWithError error: Error) {
		Task {
			await self.poi?.update(error: error)
		}
	}
}
