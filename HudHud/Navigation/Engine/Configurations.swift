//
//  Configurations.swift
//  HudHud
//
//  Created by Ali Hilal on 04/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import FerrostarCore
import FerrostarCoreFFI
import ferrostarFFI
import Foundation

// MARK: - NavigationConfig

struct NavigationConfig {

    // MARK: Static Properties

    static let `default` = NavigationConfig(routeProvider: GraphHopperRouteProvider(),
                                            locationEngine: AppDpendencies.locationEngine,
                                            stepAdvanceConfig: .default,
                                            deviationConfig: .default,
                                            courseFiltering: .snapToRoute,
                                            horizonScanRange: .kilometers(1.5),
                                            horizonUpdateInterval: 10,
                                            featureAlertConfig: .default)

    // MARK: Properties

    let routeProvider: CustomRouteProvider
    let locationEngine: LocationEngine
    let stepAdvanceConfig: StepAdvanceConfig
    let deviationConfig: DeviationConfig
    let courseFiltering: CourseFiltering

    let horizonScanRange: Measurement<UnitLength>
    let horizonUpdateInterval: TimeInterval
    let featureAlertConfig: FeatureAlertConfig

    // MARK: Functions

    func toFerrostarConfig() -> SwiftNavigationControllerConfig {
        SwiftNavigationControllerConfig(stepAdvance: self.mapStepAdvanceConfig(),
                                        routeDeviationTracking: self.mapDeviationConfig(),
                                        snappedLocationCourseFiltering: self.courseFiltering)
    }

}

// MARK: - StepAdvanceConfig

enum StepAdvanceConfig {
    case manual
    case distanceToEndOfStep(distance: UInt16, minimumHorizontalAccuracy: UInt16)
    case relativeLineString(minimumHorizontalAccuracy: UInt16, automaticAdvanceDistance: UInt16?)

    // MARK: Static Properties

    static let `default` = StepAdvanceConfig.relativeLineString(minimumHorizontalAccuracy: 32, automaticAdvanceDistance: 10)
}

// MARK: - DeviationConfig

enum DeviationConfig {
    case none
    case staticThreshold(minimumHorizontalAccuracy: UInt16, maxAcceptableDeviation: Double)
    case custom(detector: RouteDeviationDetector)

    // MARK: Static Properties

    static let `default` = DeviationConfig.staticThreshold(minimumHorizontalAccuracy: 25, maxAcceptableDeviation: 20)
}

// MARK: - FeatureAlertConfig

struct FeatureAlertConfig {

    // MARK: Static Properties

    static let `default` = FeatureAlertConfig(speedCameraConfig: .default, trafficIncidentConfig: .default, roadworkConfig: .default)

    // MARK: Properties

    let speedCameraConfig: SpeedCameraAlertConfig
    let trafficIncidentConfig: TrafficIncidentAlertConfig
    let roadworkConfig: RoadworkAlertConfig
}

// MARK: - SpeedCameraAlertConfig

struct SpeedCameraAlertConfig {

    // MARK: Static Properties

    static let `default` = SpeedCameraAlertConfig(initialAlertDistance: .kilometers(1), finalAlertDistance: .meters(200), alertRepeatInterval: 30)

    // MARK: Properties

    let initialAlertDistance: Measurement<UnitLength>
    let finalAlertDistance: Measurement<UnitLength>
    let alertRepeatInterval: TimeInterval
}

// MARK: - TrafficIncidentAlertConfig

struct TrafficIncidentAlertConfig {

    // MARK: Static Properties

    static let `default` = TrafficIncidentAlertConfig(initialAlertDistance: .kilometers(1), finalAlertDistance: .meters(500), alertRepeatInterval: 45)

    // MARK: Properties

    let initialAlertDistance: Measurement<UnitLength>
    let finalAlertDistance: Measurement<UnitLength>
    let alertRepeatInterval: TimeInterval
}

// MARK: - RoadworkAlertConfig

struct RoadworkAlertConfig {

    // MARK: Static Properties

    static let `default` = RoadworkAlertConfig(initialAlertDistance: .kilometers(3), finalAlertDistance: .kilometers(1), alertRepeatInterval: 60)

    // MARK: Properties

    let initialAlertDistance: Measurement<UnitLength>
    let finalAlertDistance: Measurement<UnitLength>
    let alertRepeatInterval: TimeInterval
}

private extension NavigationConfig {
    func mapStepAdvanceConfig() -> StepAdvanceMode {
        switch self.stepAdvanceConfig {
        case .manual:
            return .manual
        case let .distanceToEndOfStep(distance, accuracy):
            return .distanceToEndOfStep(distance: distance, minimumHorizontalAccuracy: accuracy)
        case let .relativeLineString(accuracy, distance):
            return .relativeLineStringDistance(minimumHorizontalAccuracy: accuracy, automaticAdvanceDistance: distance)
        }
    }

    func mapDeviationConfig() -> SwiftRouteDeviationTracking {
        switch self.deviationConfig {
        case .none:
            return .none
        case let .staticThreshold(accuracy, deviation):
            return .staticThreshold(minimumHorizontalAccuracy: accuracy, maxAcceptableDeviation: deviation)
        case .custom:
            return .none
        }
    }
}
