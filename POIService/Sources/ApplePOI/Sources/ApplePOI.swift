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

final class ApplePOI: POIServiceProtocol {
    
    static let serviceName: String = "Apple"

    func search(term: String) async throws -> [POI] {
        let coordinate = CLLocationCoordinate2D(latitude: 24.774265, longitude: 46.738586)

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = term
        request.region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 100, longitudinalMeters: 100)

        let search = MKLocalSearch(request: request)
        let result = try await search.start()

        print("Region: \(result.boundingRegion)")
        print("Results: \(result.mapItems)")
        return result.mapItems.map {
            return POI(name: $0.name ?? "Unknown", locationCoordinate: $0.placemark.coordinate, type: $0.pointOfInterestCategory?.rawValue ?? "Unknown")
        }
    }
}
