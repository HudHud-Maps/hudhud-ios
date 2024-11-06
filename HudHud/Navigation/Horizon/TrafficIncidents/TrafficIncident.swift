//
//  TrafficIncident.swift
//  HudHud
//
//  Created by Ali Hilal on 04/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation

// MARK: - TrafficIncidentType

enum TrafficIncidentType: String, Codable, Equatable {
    case accident
    case congestion
    case construction
    case roadClosure
    case roadHazard
    case weatherCondition
    case other
}

// MARK: - TrafficIncidentSeverity

enum TrafficIncidentSeverity: Int, Codable, Equatable {
    case low = 1 // Minor impact
    case moderate = 2 // Moderate impact
    case major = 3 // Significant impact
    case severe = 4 // Critical impact

    // MARK: Computed Properties

    var description: String {
        switch self {
        case .low: return "Minor"
        case .moderate: return "Moderate"
        case .major: return "Major"
        case .severe: return "Severe"
        }
    }
}

// MARK: - TrafficIncident

struct TrafficIncident: Equatable, Identifiable {

    // MARK: Properties

    let id: String
    let type: TrafficIncidentType
    let severity: TrafficIncidentSeverity
    let location: CLLocationCoordinate2D
    let description: String
    let startTime: Date
    let endTime: Date?
    let length: Measurement<UnitLength>?
    let delayInSeconds: TimeInterval?

    // MARK: Computed Properties

    var isActive: Bool {
        let now = Date()
        return now >= self.startTime && (self.endTime == nil || now <= self.endTime!)
    }

    var alertDistance: Measurement<UnitLength> {
        switch self.severity {
        case .severe:
            return .init(value: 3, unit: .kilometers)
        case .major:
            return .init(value: 2, unit: .kilometers)
        case .moderate:
            return .init(value: 1.5, unit: .kilometers)
        case .low:
            return .init(value: 1, unit: .kilometers)
        }
    }
}
