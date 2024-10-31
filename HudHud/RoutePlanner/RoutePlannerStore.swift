//
//  RoutePlannerStore.swift
//  HudHud
//
//  Created by Naif Alrashed on 30/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import FerrostarCoreFFI
import Foundation

// MARK: - RoutePlannerStore

@Observable
@MainActor
final class RoutePlannerStore {

    // MARK: Properties

    var state: RoutePlanningState = .initialLoading

    private let initialDestination: ResolvedItem
    private let sheetStore: SheetStore
    private let userLocationStore: UserLocationStore
    private let mapStore: MapStore
    private let routePlanner: RoutePlanner = .init(
        routingService: GraphHopperRouteProvider()
    )
    private let routingStore: RoutingStore

    // MARK: Lifecycle

    init(
        sheetStore: SheetStore,
        userLocationStore: UserLocationStore,
        mapStore: MapStore,
        routingStore: RoutingStore,
        destination: ResolvedItem
    ) {
        self.initialDestination = destination
        self.sheetStore = sheetStore
        self.mapStore = mapStore
        self.userLocationStore = userLocationStore
        self.routingStore = routingStore
        Task {
            await self.fetchRoutePlan()
        }
    }

    // MARK: Functions

    func onAppear() {
        guard case .loaded = self.state else { return }
        self.sheetStore.currentSheet.detentData.value = DetentData(
            selectedDetent: .third,
            allowedDetents: [.third]
        )
    }

    func addNewRoute() {
        fatalError("show the add route page here")
        self.sheetStore.show(.debugView)
    }

    func startNavigation() {
        self.routingStore.startNavigation()
    }

    private func fetchRoutePlan() async {
        guard let userLocation = await self.userLocationStore.location(allowCached: false) else {
            self.state = .locationNotEnabled
            return
        }
        let userLocationWaypoint = Waypoint(
            coordinate: GeographicCoordinate(cl: userLocation.coordinate),
            kind: .break
        )
        let destinationWaypoint = Waypoint(
            coordinate: GeographicCoordinate(cl: self.initialDestination.coordinate),
            kind: .break
        )
        do {
            let routes = try await self.routePlanner.planRoutes(
                from: userLocationWaypoint,
                to: destinationWaypoint
            )
            let plan = RoutePlan(
                waypoints: [
                    RouteWaypoint(type: .userLocation, title: "User Location"),
                    RouteWaypoint(type: .location(self.initialDestination), title: self.initialDestination.title)
                ],
                routes: routes,
                selectedRoute: routes.first!
            )
            self.state = .loaded(plan: plan)
            switch self.sheetStore.currentSheet.sheetType {
            case let .routePlanner(store) where store === self:
                self.sheetStore.currentSheet.detentData.value = DetentData(
                    selectedDetent: .third,
                    allowedDetents: [.third]
                )
            default:
                break
            }
        } catch {
            self.state = .errorFetchignRoute
        }
    }
}

// MARK: - RoutePlanningState

enum RoutePlanningState: Hashable {
    case initialLoading
    case locationNotEnabled
    case errorFetchignRoute
    case loaded(plan: RoutePlan)

    // MARK: Computed Properties

    var destinations: [RouteWaypoint] {
        switch self {
        case .initialLoading, .locationNotEnabled, .errorFetchignRoute:
            []
        case let .loaded(plan):
            plan.waypoints
        }
    }
}

// MARK: - RoutePlan

struct RoutePlan: Hashable {
    var waypoints: [RouteWaypoint]
    var routes: [Route]
    var selectedRoute: Route
}

// MARK: - RoutePlannerStore + Previewable

extension RoutePlannerStore: Previewable {
    static let storeSetUpForPreviewing = RoutePlannerStore(
        sheetStore: .storeSetUpForPreviewing,
        userLocationStore: .storeSetUpForPreviewing,
        mapStore: .storeSetUpForPreviewing,
        routingStore: .storeSetUpForPreviewing,
        destination: .artwork
    )
}
