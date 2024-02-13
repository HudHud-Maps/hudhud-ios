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

extension MKPointOfInterestCategory {

	static let travelPointsOfInterest: [MKPointOfInterestCategory] = [.bakery, .brewery, .cafe, .restaurant, .winery, .hotel]
	static let defaultPointOfInterestSymbolName = "mappin.and.ellipse"

	var symbolName: String {
		switch self {
		case .airport:
			return "airplane"
		case .atm, .bank:
			return "banknote"
		case .bakery, .brewery, .cafe, .foodMarket, .restaurant, .winery:
			return "fork.knife"
		case .campground, .hotel:
			return "bed.double"
		case .carRental, .evCharger, .gasStation, .parking:
			return "car"
		case .laundry, .store:
			return "tshirt"
		case .library, .museum, .school, .theater, .university:
			return "building.columns"
		case .nationalPark, .park:
			return "leaf"
		case .postOffice:
			return "envelope"
		case .publicTransport:
			return "bus"
		default:
			return MKPointOfInterestCategory.defaultPointOfInterestSymbolName
		}
	}
}
