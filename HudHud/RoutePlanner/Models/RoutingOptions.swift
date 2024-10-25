//
//  RoutingOptions.swift
//  HudHud
//
//  Created by Ali Hilal on 19/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

struct RoutingOptions {

    // MARK: Nested Types

    enum Geometry: String {
        case polyline
        case polyline6
        case geojson
    }

    enum Overview: String {
        case simplified
        case full
        case `false`
    }

    enum Annotation: String, CaseIterable {
        case duration
        case distance
        case speed
        case congestion
    }

    enum VoiceUnits: String {
        case imperial
        case metric
    }

    // MARK: Properties

    var accessToken: String = ""
    var alternatives: Bool = false
    var geometries: Geometry = .polyline6
    var overview: Overview = .full
    var steps: Bool = true
    var continueStraight: Bool = true
    var annotations: Set<Annotation> = [.congestion, .distance]
    var language: String = Locale.preferredLanguages.first ?? "en-US"
    var roundaboutExits: Bool = true
    var voiceInstructions: Bool = true
    var bannerInstructions: Bool = true
    var voiceUnits: VoiceUnits = .metric

    // MARK: Computed Properties

    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "access_token", value: self.accessToken),
            URLQueryItem(name: "alternatives", value: self.alternatives.description),
            URLQueryItem(name: "geometries", value: self.geometries.rawValue),
            URLQueryItem(name: "overview", value: self.overview.rawValue),
            URLQueryItem(name: "steps", value: self.steps.description),
            URLQueryItem(name: "continue_straight", value: self.continueStraight.description),
            URLQueryItem(name: "annotations", value: self.annotations.map(\.rawValue).joined(separator: ",")),
            URLQueryItem(name: "language", value: self.language),
            URLQueryItem(name: "roundabout_exits", value: self.roundaboutExits.description),
            URLQueryItem(name: "voice_instructions", value: self.voiceInstructions.description),
            URLQueryItem(name: "banner_instructions", value: self.bannerInstructions.description),
            URLQueryItem(name: "voice_units", value: self.voiceUnits.rawValue)
        ]
    }
}
