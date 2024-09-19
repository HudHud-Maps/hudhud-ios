//
//  CLLocationCoordinate2D+GeoJSON.swift
//  BackendService
//
//  Created by Patrick Kladek on 15.07.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import LocationFormatter

public extension CLLocationCoordinate2D {

    enum GeoJSONError: LocalizedError {
        case invalidCoordinates
        case invalidType

        // MARK: Computed Properties

        public var errorDescription: String? {
            switch self {
            case .invalidCoordinates:
                "Can not read coordinates"
            case .invalidType:
                "Expecting different GeoJSON type"
            }
        }

        public var failureReason: String? {
            switch self {
            case .invalidCoordinates:
                "data has more or less then 2 coordinates, expecting exactly 2"
            case .invalidType:
                "type should be either LineString or Point"
            }
        }
    }

    init(geoJSON array: [Double]) throws {
        guard array.count == 2 else {
            throw GeoJSONError.invalidCoordinates
        }

        self.init(latitude: array[1], longitude: array[0])
    }

    init(geoJSON point: JSONDictionary) throws {
        guard point["type"] as? String == "Point" else {
            throw GeoJSONError.invalidType
        }

        try self.init(geoJSON: point["coordinates"] as? [Double] ?? [])
    }

    static func coordinates(geoJSON lineString: JSONDictionary) throws -> [CLLocationCoordinate2D] {
        let type = lineString["type"] as? String
        guard type == "LineString" || type == "Point" else {
            throw GeoJSONError.invalidType
        }

        let coordinates = lineString["coordinates"] as? [[Double]] ?? []
        return try coordinates.map { try self.init(geoJSON: $0) }
    }

    func formatted() -> String {
        let formatter = LocationCoordinateFormatter()
        formatter.format = .decimalDegrees
        return formatter.string(from: self) ?? "Invalid Coordinates" // "48.11638° N, 122.74231° W"
    }
}

public extension CLLocation {

    var coordinateString: String {
        return "\(self.coordinate.latitude.format(f: ".3"))° N \(self.coordinate.longitude.format(f: ".3"))° W"
    }

    var isValid: Bool {
        let coordinate = self.coordinate
        guard coordinate.latitude >= -90, coordinate.latitude <= 90 else {
            return false
        }

        if coordinate.latitude == 0,
           coordinate.longitude == 0 {
            return false
        }

        return true
    }
}

private extension Double {
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}
