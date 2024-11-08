//
//  RoutePlanningState.swift
//  HudHud
//
//  Created by Patrick Kladek on 07.11.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import FerrostarCoreFFI
import Foundation

enum RoutePlanningState: Hashable {
    case initialLoading
    case locationNotEnabled
    case errorFetchignRoute
    case loaded(plan: RoutePlan)

    // MARK: Computed Properties

    var destinations: [RouteWaypoint] {
        get {
            switch self {
            case .initialLoading, .locationNotEnabled, .errorFetchignRoute:
                []
            case let .loaded(plan):
                plan.waypoints
            }
        }
        set {
            switch self {
            case let .loaded(plan):
                self = .loaded(plan: RoutePlan(waypoints: newValue, routes: plan.routes, selectedRoute: plan.selectedRoute))
            case .errorFetchignRoute, .initialLoading, .locationNotEnabled:
                break
            }
        }
    }

    var selectedRoute: Route? {
        switch self {
        case .initialLoading, .locationNotEnabled, .errorFetchignRoute:
            nil
        case let .loaded(plan):
            plan.selectedRoute
        }
    }

    var canSwap: Bool {
        self.destinations.count == 2
    }

    var canRemove: Bool {
        self.destinations.count > 2
    }

    var canDrag: Bool {
        self.destinations.count > 2
    }
}
