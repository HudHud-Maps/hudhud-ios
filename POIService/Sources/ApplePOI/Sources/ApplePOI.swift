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

public final class ApplePOI: NSObject, POIServiceProtocol {

	public enum State {
		case completion
		case search
	}

	private var localSearch: MKLocalSearch?
	private var completer: MKLocalSearchCompleter
	private var cancellable: AnyCancellable?

	// MARK: - Properties

	public static var serviceName: String = "Apple"
	public var state: State = .completion
	public var searchQuery: String = "" {
		didSet {
			if self.searchQuery.isEmpty {
				self.results = []
			} else {
				switch self.state {
				case .completion:
					self.completer.queryFragment = self.searchQuery
				case .search:
					let request = MKLocalSearch.Request()
					request.naturalLanguageQuery = searchQuery
					self.search(using: request)
				}
			}
		}
	}
	@Published public var results: [Row] = []
	@Published public private(set) var error: Error?

	// MARK: - Lifecycle

	public override init() {
		self.completer = MKLocalSearchCompleter()
		super.init()
		self.completer.delegate = self
	}
}

// MARK: - MKLocalSearchCompleterDelegate

extension ApplePOI: MKLocalSearchCompleterDelegate {

	public func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
		self.results = completer.results.map {
			Row(appleCompletion: $0)
		}
	}

	public func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
		self.error = error
	}
}

// MARK: - Private

private extension ApplePOI {

	func search(using searchRequest: MKLocalSearch.Request) {
		searchRequest.resultTypes = .pointOfInterest

		self.localSearch = MKLocalSearch(request: searchRequest)
		self.localSearch?.start { [unowned self] (response, error) in
			guard error == nil else {
				self.error = error
				return
			}

			self.results = response?.mapItems.map {
				Row(mapItem: $0)
			} ?? []

//			// This view controller sets the map view's region in `prepareForSegue` based on the search response's bounding region.
//			if let updatedRegion = response?.boundingRegion {
//				self.searchRegion = updatedRegion
//			}
		}
	}
}
