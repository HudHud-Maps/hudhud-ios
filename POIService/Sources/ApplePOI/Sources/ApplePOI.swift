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

public final class ApplePOI: NSObject, POIServiceProtocol, ObservableObject {

	private var searchCompletionContinuation: [CheckedContinuation<[POI], Error>] = []
	private var searchCompleter: MKLocalSearchCompleter

	public static let serviceName: String = "Apple"

	public override init() {
		self.searchCompleter = .init()
		super.init()
		self.searchCompleter.region = MKCoordinateRegion(MKMapRect.world)
		self.searchCompleter.resultTypes = .pointOfInterest
		self.searchCompleter.pointOfInterestFilter = MKPointOfInterestFilter(including: MKPointOfInterestCategory.travelPointsOfInterest)
		self.searchCompleter.delegate = self
	}

	public func search(term: String) async throws -> [POI] {
		let coordinate = CLLocationCoordinate2D(latitude: 24.774265, longitude: 46.738586)

		let request = MKLocalSearch.Request()
		request.naturalLanguageQuery = term
		request.region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 100, longitudinalMeters: 100)

		let search = MKLocalSearch(request: request)
		let result = try await search.start()

		print("Region: \(result.boundingRegion)")
		print("Results: \(result.mapItems)")
		return result.mapItems.map {
			return POI(name: $0.name ?? "Unknown",
					   subtitle: "<Address>",
					   locationCoordinate: $0.placemark.coordinate,
					   type: $0.pointOfInterestCategory?.rawValue ?? "Unknown")
		}
	}

	@MainActor
	public func complete(term: String) async throws -> [POI] {
		print("complete: \(term)")

		searchCompletionContinuation.forEach { $0.resume(returning: []) }
		searchCompletionContinuation.removeAll()

		return try await withCheckedThrowingContinuation { continuation in
			self.searchCompletionContinuation.append(continuation)
			self.searchCompleter.queryFragment = term
		}
	}
}

extension ApplePOI: MKLocalSearchCompleterDelegate {

	public func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
		let pois = completer.results.map {
			let poi = POI(name: $0.title, subtitle: $0.subtitle, locationCoordinate: .init(), type: "")
			print("poi: \(poi)")
			return poi
		}
		searchCompletionContinuation.forEach { $0.resume(returning: pois) }
		searchCompletionContinuation.removeAll()
	}

	public func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
		searchCompletionContinuation.forEach { $0.resume(throwing: error) }
		searchCompletionContinuation.removeAll()
	}
}

public class LocationSearchService: NSObject, ObservableObject, Identifiable {

	var completer: MKLocalSearchCompleter
	var cancellable: AnyCancellable?

	public var searchQuery = "" {
		didSet {
			if self.searchQuery.isEmpty {
				self.completions = []
			} else {
				self.completer.queryFragment = self.searchQuery
			}
		}
	}
	@Published public var completions: [POI] = []

	// MARK: - Lifecycle

	public override init() {
		completer = MKLocalSearchCompleter()
		super.init()
		completer.delegate = self
	}
}

// MARK: - MKLocalSearchCompleterDelegate

extension LocationSearchService: MKLocalSearchCompleterDelegate {

	public func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
		self.completions = completer.results.map {
			POI(name: $0.title, subtitle: $0.subtitle, locationCoordinate: .init(), type: "")
		}
	}
}
