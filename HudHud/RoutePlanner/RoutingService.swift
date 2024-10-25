//
//  RoutingService.swift
//  HudHud
//
//  Created by Ali Hilal on 19/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import FerrostarCoreFFI
import Foundation

protocol RoutingService {
    func calculateRoute(
        from start: Waypoint,
        to end: Waypoint,
        passingBy waypoints: [Waypoint]
    ) async throws -> [Route]
}

//
// struct RoutingResponse: Codable {
//    let code: String
//    let routes: [Route]
//    let waypoints: [Waypoint]
//    let uuid: String
//
//
//    // MARK: - Route
//    struct Route: Codable {
//        let geometry: String
//        let distance, duration, weight: Double
//        let weightName: String
//        let legs: [Leg]
//        let voiceLocale: String
//
//        enum CodingKeys: String, CodingKey {
//            case geometry, distance, duration, weight
//            case weightName = "weight_name"
//            case legs, voiceLocale
//        }
//    }
//
//    // MARK: - Leg
//    struct Leg: Codable {
//        let annotation: Annotation
//        let summary: String
//        let weight, duration: Double
//        let steps: [Step]
//        let distance: Double
//    }
//
//    // MARK: - Annotation
//    struct Annotation: Codable {
//        let congestion: [Congestion]
//        let congestionNumeric: [Int?]
//        let distance, duration: [Int]
//        let maxspeed: [Maxspeed]
//        let speed: [Int]
//
//        enum CodingKeys: String, CodingKey {
//            case congestion
//            case congestionNumeric = "congestion_numeric"
//            case distance, duration, maxspeed, speed
//        }
//    }
//
//    enum Congestion: String, Codable {
//        case heavy = "heavy"
//        case low = "low"
//        case moderate = "moderate"
//        case severe = "severe"
//        case unknown = "unknown"
//    }
//
//    // MARK: - Maxspeed
//    struct Maxspeed: Codable {
//        let unknown: Bool?
//        let speed: Int?
//        let unit: Unit?
//    }
//
//    enum Unit: String, Codable {
//        case kmH = "km/h"
//    }
//
//    // MARK: - Step
//    struct Step: Codable {
//        let intersections: [Intersection]
//        let drivingSide: DrivingSide
//        let geometry: String
//        let mode: Mode
//        let maneuver: Maneuver
//        let weight, duration: Double
//        let name: String
//        let distance: Double
//        let voiceInstructions: [VoiceInstruction]?
//        let bannerInstructions: [BannerInstruction]?
//
//        enum CodingKeys: String, CodingKey {
//            case intersections
//            case drivingSide = "driving_side"
//            case geometry, mode, maneuver, weight, duration, name, distance, voiceInstructions, bannerInstructions
//        }
//    }
//
//    // MARK: - BannerInstruction
//    struct BannerInstruction: Codable {
//        let distanceAlongGeometry: Double
//        let primary: Primary
//        let sub: Primary?
//    }
//
//    // MARK: - Primary
//    struct Primary: Codable {
//        let text: String
//        let components: [Component]
//        let type: PrimaryType
//        let modifier: DrivingSide?
//    }
//
//    // MARK: - Component
//    struct Component: Codable {
//        let text: String
//        let type: ComponentType
//    }
//
//    enum ComponentType: String, Codable {
//        case text = "text"
//    }
//
//    enum DrivingSide: String, Codable {
//        case drivingSideLeft = "left"
//        case drivingSideRight = "right"
//        case slightLeft = "slight left"
//        case slightRight = "slight right"
//        case straight = "straight"
//        case uturn = "uturn"
//    }
//
//    enum PrimaryType: String, Codable {
//        case arrive = "arrive"
//        case depart = "depart"
//        case roundabout = "roundabout"
//        case turn = "turn"
//    }
//
//    // MARK: - Intersection
//    struct Intersection: Codable {
//        let out: Int
//        let entry: [Bool]
//        let bearings: [Int]
//        let location: [Double]
//        let geometryIndex, intersectionIn: Int
//
//        enum CodingKeys: String, CodingKey {
//            case out, entry, bearings, location
//            case geometryIndex = "geometry_index"
//            case intersectionIn = "in"
//        }
//    }
//
//    // MARK: - Maneuver
//    struct Maneuver: Codable {
//        let bearingAfter, bearingBefore: Int
//        let location: [Double]
//        let modifier: DrivingSide?
//        let type: PrimaryType
//        let instruction: String
//
//        enum CodingKeys: String, CodingKey {
//            case bearingAfter = "bearing_after"
//            case bearingBefore = "bearing_before"
//            case location, modifier, type, instruction
//        }
//    }
//
//    enum Mode: String, Codable {
//        case driving = "driving"
//    }
//
//    // MARK: - VoiceInstruction
//    struct VoiceInstruction: Codable {
//        let distanceAlongGeometry: Double
//        let announcement, ssmlAnnouncement: String
//    }
//
//    // MARK: - Waypoint
//    struct Waypoint: Codable {
//        let name: String
//        let location: [Double]
//    }
// }
