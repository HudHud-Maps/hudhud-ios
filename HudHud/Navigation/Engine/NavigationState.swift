//
//  NavigationState.swift
//  HudHud
//
//  Created by Ali Hilal on 04/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import FerrostarCore
import FerrostarCoreFFI
import ferrostarFFI
import Foundation
import MapLibre

public typealias TripState = FerrostarCoreFFI.TripState
public typealias RouteStep = FerrostarCoreFFI.RouteStep
public typealias Waypoint = FerrostarCoreFFI.Waypoint
public typealias TripProgress = FerrostarCoreFFI.TripProgress
public typealias RouteDeviation = FerrostarCoreFFI.RouteDeviation
public typealias VisualInstruction = FerrostarCoreFFI.VisualInstruction
public typealias SpokenInstruction = FerrostarCoreFFI.SpokenInstruction
public typealias RouteDeviationDetector = FerrostarCoreFFI.RouteDeviationDetector
public typealias Route = FerrostarCoreFFI.Route
public typealias UserLocation = FerrostarCoreFFI.UserLocation

// MARK: - TripState.NavigationInfo

extension TripState {
    struct NavigationInfo {

        // MARK: Properties

        let stepIndex: UInt64?
        let location: UserLocation
        let steps: [RouteStep]
        let waypoints: [Waypoint]
        let progress: TripProgress
        let deviation: RouteDeviation
        let instruction: VisualInstruction?
        let voice: SpokenInstruction?
        let metadata: String?

        // MARK: Lifecycle

        init(from tripState: TripState) throws {
            guard case let .navigating(index,
                                       location,
                                       steps,
                                       waypoints,
                                       progress,
                                       deviation,
                                       visual,
                                       spoken,
                                       annotations) = tripState else {
                throw NavigationError.invalidState
            }
            self.stepIndex = index
            self.location = location
            self.steps = steps
            self.waypoints = waypoints
            self.progress = progress
            self.deviation = deviation
            self.instruction = visual
            self.voice = spoken
            self.metadata = annotations
        }
    }
}

extension TripState {

    var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }

    var isNavigating: Bool {
        if case .navigating = self { return true }
        return false
    }

    var isComplete: Bool {
        if case .complete = self { return true }
        return false
    }

    var navigationInfo: NavigationInfo? {
        try? NavigationInfo(from: self)
    }

    var currentLocation: UserLocation? {
        self.navigationInfo?.location
    }

    var currentProgress: TripProgress? {
        self.navigationInfo?.progress
    }

    var currentInstruction: VisualInstruction? {
        self.navigationInfo?.instruction
    }

    var currentAnnouncement: SpokenInstruction? {
        self.navigationInfo?.voice
    }

    var remainingSteps: [RouteStep]? {
        self.navigationInfo?.steps
    }

    var remainingWaypoints: [Waypoint]? {
        self.navigationInfo?.waypoints
    }

    var isOnRoute: Bool {
        guard let deviation = navigationInfo?.deviation else { return false }
        if case .noDeviation = deviation { return true }
        return false
    }

    var routeDeviation: Double? {
        guard let deviation = navigationInfo?.deviation else { return nil }
        if case let .offRoute(distance) = deviation { return distance }
        return nil
    }

    var distanceToNextManeuver: Double? {
        self.currentProgress?.distanceToNextManeuver
    }

    var distanceRemaining: Double? {
        self.currentProgress?.distanceRemaining
    }

    var timeRemaining: Double? {
        self.currentProgress?.durationRemaining
    }

    var currentRoadName: String? {
        self.remainingSteps?.first?.roadName?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var primaryInstruction: String? {
        self.currentInstruction?.primaryContent.text
    }

    var secondaryInstruction: String? {
        self.currentInstruction?.secondaryContent?.text
    }

    var hasLaneGuidance: Bool {
        self.currentInstruction?.subContent?.laneInfo != nil
    }

    var laneGuidance: [LaneInfo]? {
        self.currentInstruction?.subContent?.laneInfo
    }
}

extension TripState {
    func ifNavigating(_ handler: (NavigationInfo) -> Void) {
        if let info = navigationInfo {
            handler(info)
        }
    }
}

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

public extension BoundingBox {
    var mlnCoordinateBounds: MLNCoordinateBounds {
        return MLNCoordinateBounds(sw: self.sw.clLocationCoordinate2D, ne: self.ne.clLocationCoordinate2D)
    }
}

public extension [GeographicCoordinate] {
    var clLocationCoordinate2Ds: [CLLocationCoordinate2D] {
        return self.map(\.clLocationCoordinate2D)
    }
}
