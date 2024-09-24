//
//  Ferrostar.swift
//  BackendService
//
//  Created by patrick on 18.09.24.
//

import CoreLocation
import FerrostarCore
import FerrostarCoreFFI
import Foundation
import MapLibre

public extension Waypoint {
    init(coordinate: CLLocationCoordinate2D, kind: WaypointKind = .via) {
        self.init(coordinate: GeographicCoordinate(lat: coordinate.latitude, lng: coordinate.longitude), kind: kind)
    }

    var cLCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: self.coordinate.lat, longitude: self.coordinate.lng)
    }
}

public extension Route {
    var duration: TimeInterval {
        // add together all routeStep durations
        return self.steps.reduce(0) { $0 + $1.duration }
    }
}

// MARK: - Route + Identifiable

extension Route: @retroactive Identifiable {
    public var id: Int {
        return self.hashValue
    }

}

extension BoundingBox {
    var mlnCoordinateBounds: MLNCoordinateBounds {
        return MLNCoordinateBounds(sw: self.sw.clLocationCoordinate2D, ne: self.ne.clLocationCoordinate2D)
    }
}

extension [GeographicCoordinate] {
    var clLocationCoordinate2Ds: [CLLocationCoordinate2D] {
        return self.map(\.clLocationCoordinate2D)
    }
}

extension FerrostarCore {

    var isNavigating: Bool {
        if let tripState = self.state?.tripState, case .navigating = tripState {
            return true
        } else {
            return false
        }
    }
}
