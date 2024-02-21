//
//  ApplePOI.swift
//  ApplePOI
//
//  Created by Patrick Kladek on 01.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import POIService
import CoreLocation
import MapKit
import Combine
import SwiftUI

public final actor ApplePOI: NSObject, POIServiceProtocol {

	private var localSearch: MKLocalSearch?
	private var completer: MKLocalSearchCompleter
	private var cancellable: AnyCancellable?
	private var continuation: CheckedContinuation<[Row], Error>?
	private let delegate: DelegateWrapper

	// MARK: - Lifecycle

	public override init() {
		self.completer = MKLocalSearchCompleter()
		self.delegate = .init()
		super.init()
		self.delegate.poi = self
		self.completer.delegate = self.delegate
	}

	// MARK: - POIServiceProtocol

	public static var serviceName: String = "Apple"

	public func lookup(prediction: PredictionResult) async throws -> [Row] {
		guard case .apple(let completion) = prediction else {
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

				let rows = mapItems.map {
					Row(mapItem: $0)
				}
				continuation.resume(returning: rows)
			}
		}
	}

	public func predict(term: String) async throws -> [Row] {
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

	func update(results: [Row]) async {
		self.continuation?.resume(returning: results)
		self.continuation = nil
	}

	func update(error: Error) async {
		self.continuation?.resume(throwing: error)
		self.continuation = nil
	}
}

// MARK: - Delegate

private class DelegateWrapper: NSObject, MKLocalSearchCompleterDelegate {

	weak var poi: ApplePOI?

	// MARK: - MKLocalSearchCompleterDelegate

	func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
		let results = completer.results.map {
			Row(appleCompletion: $0)
		}
		Task {
			await self.poi?.update(results: results)
		}
	}

	func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
		Task {
			await self.poi?.update(error: error)
		}
	}
}
