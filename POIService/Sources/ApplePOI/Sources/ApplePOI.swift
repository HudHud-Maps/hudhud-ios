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

	private var completer: MKLocalSearchCompleter
	private var cancellable: AnyCancellable?

	// MARK: - Properties

	public static var serviceName: String = "Apple"
	public var searchQuery = "" {
		didSet {
			if self.searchQuery.isEmpty {
				self.completions = []
			} else {
				self.completer.queryFragment = self.searchQuery
			}
		}
	}
	@Published public var completions: [Row] = []
	@Published public private(set) var error: Error?

	// MARK: - Lifecycle

	public override init() {
		completer = MKLocalSearchCompleter()
		super.init()
		completer.delegate = self
	}
}

// MARK: - MKLocalSearchCompleterDelegate

extension ApplePOI: MKLocalSearchCompleterDelegate {

	public func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
		self.completions = completer.results.map {
			Row(appleCompletion: $0)
		}
	}

	public func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
		self.error = error
	}
}
