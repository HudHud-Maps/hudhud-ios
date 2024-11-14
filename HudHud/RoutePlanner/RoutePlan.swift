//
//  RoutePlan.swift
//  HudHud
//
//  Created by Patrick Kladek on 07.11.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import FerrostarCoreFFI
import Foundation

// MARK: - RoutePlan

struct RoutePlan: Hashable {
    var waypoints: [RouteWaypoint]
    var routes: [RouteViewData]
    var selectedRoute: Route
}

// MARK: - RouteViewData

struct RouteViewData: Hashable, Identifiable {

    // MARK: Properties

    let distance: String
    let duration: String
    let summary: String

    let model: Route

    // MARK: Computed Properties

    var id: Int {
        self.model.id
    }

    // MARK: Lifecycle

    init(_ route: Route) {
        self.model = route
        self.distance = distanceFormatter.string(
            from: Measurement.meters(route.distance)
                .converted(to: .kilometers)
        )
        self.duration = durationFormatter.string(
            from: Date(),
            to: Date(timeIntervalSinceNow: route.duration)
        ) ?? ""
        self.summary = "A close destination"
    }
}

private let distanceFormatter: MeasurementFormatter = {
    let distanceFormatter = MeasurementFormatter()
    distanceFormatter.unitOptions = .providedUnit
    distanceFormatter.unitStyle = .medium
    return distanceFormatter
}()

private let durationFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute]
    formatter.unitsStyle = .brief
    formatter.zeroFormattingBehavior = .dropAll
    return formatter
}()
