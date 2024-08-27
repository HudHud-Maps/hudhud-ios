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
import SwiftUI

// MARK: - ApplePOI

public actor ApplePOI: POIServiceProtocol {

    // MARK: Static Properties

    // MARK: - POIServiceProtocol

    public static var serviceName: String = "Apple"

    // MARK: Properties

    private var localSearch: MKLocalSearch?
    private var completer: MKLocalSearchCompleter
    private var continuation: CheckedContinuation<POIResponse, Error>?
    private let delegate: DelegateWrapper

    // MARK: Lifecycle

    public init() {
        self.completer = MKLocalSearchCompleter()
        self.delegate = DelegateWrapper()
        self.delegate.apple = self
        Task {
            await self.completer.delegate = self.delegate
        }
    }

    // MARK: Functions

    public func lookup(id: String, prediction: Any, baseURL _: String) async throws -> [ResolvedItem] {
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
                    return ResolvedItem(id: mapItems.count == 1 ? id : "\($0.name ?? "")|\($0.placemark.formattedAddress ?? "")",
                                        title: $0.name ?? "",
                                        subtitle: $0.placemark.formattedAddress ?? "",
                                        category: $0.pointOfInterestCategory?.rawValue.replacingOccurrences(of: "MKPOICategory", with: ""),
                                        symbol: $0.pointOfInterestCategory?.symbol ?? .pin,
                                        type: .appleResolved,
                                        coordinate: $0.placemark.coordinate,
                                        color: .systemRed,
                                        phone: $0.phoneNumber,
                                        website: $0.url)
                }
                continuation.resume(returning: items)
            }
        }
    }

    public func predict(term: String, coordinates: CLLocationCoordinate2D?, baseURL _: String) async throws -> POIResponse {
        return try await withCheckedThrowingContinuation { continuation in
            if let continuation = self.continuation {
                self.completer.cancel()
                continuation.resume(returning: POIResponse(items: [], hasCategory: false))
                self.continuation = nil
            }

            if term.isEmpty {
                continuation.resume(returning: POIResponse(items: [], hasCategory: false))
                return
            }

            self.continuation = continuation
            DispatchQueue.main.sync {
                self.completer.queryFragment = term
                if let coords = coordinates {
                    let region = MKCoordinateRegion(center: coords, latitudinalMeters: 5000, longitudinalMeters: 5000)
                    self.completer.region = region
                }
            }
        }
    }

    // MARK: - Internal

    func update(results: [DisplayableRow]) async {
        self.continuation?.resume(returning: POIResponse(items: results, hasCategory: false))
        self.continuation = nil
    }

    func update(error: Error) async {
        self.continuation?.resume(throwing: error)
        self.continuation = nil
    }
}

// MARK: - DelegateWrapper

private class DelegateWrapper: NSObject, MKLocalSearchCompleterDelegate {

    // MARK: Properties

    weak var apple: ApplePOI?

    // MARK: Functions

    // MARK: - MKLocalSearchCompleterDelegate

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results: [DisplayableRow] = completer.results.compactMap {
            let item = PredictionItem(id: "\($0.title)|\($0.subtitle)",
                                      title: $0.title,
                                      subtitle: $0.subtitle,
                                      symbol: .pin,
                                      type: .apple(completion: $0))
            return .predictionItem(item)
        }
        Task {
            await self.apple?.update(results: results)
        }
    }

    // MARK: - Internal

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
