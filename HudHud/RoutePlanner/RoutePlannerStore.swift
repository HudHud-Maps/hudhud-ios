//
//  RoutePlannerStore.swift
//  HudHud
//
//  Created by Naif Alrashed on 30/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import Combine
import CoreLocation
import FerrostarCoreFFI
import Foundation
import SwiftUI

// MARK: - RoutePlannerStore

@Observable
@MainActor
final class RoutePlannerStore {

    // MARK: Properties

    private(set) var routePlan: RoutePlan?
    private(set) var isLoading = false
    private(set) var routeFetchingError: RoutePlanningError?

    private let initialDestination: DestinationPointOfInterest
    private let sheetStore: SheetStore
    private let userLocationStore: UserLocationStore
    private let routesPlanMapDrawer: RoutesPlanMapDrawer
    private let mapStore: MapStore
    private let routePlanner = RoutePlanner(
        routingService: GraphHopperRouteProvider()
    )
    private let navigationStore: NavigationStore
    private var routeMapEventSubscription: AnyCancellable?
    private let rowHeight: CGFloat = 56 + 6

    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Computed Properties

    var sheetContext: (detentData: CurrentValueSubject<DetentData, Never>, sheetEvents: any Publisher<SheetEvent, Never>)? {
        didSet {
            guard let sheetContext else { return }
            updateHeight()
            bindMapDrawing(to: sheetContext.sheetEvents)
        }
    }

    var canSwap: Bool {
        (self.routePlan?.waypoints.count ?? 0) == 2
    }

    var canRemove: Bool {
        (self.routePlan?.waypoints.count ?? 0) > 2
    }

    var canMove: Bool {
        (self.routePlan?.waypoints.count ?? 0) > 2
    }

    // MARK: Lifecycle

    init(
        sheetStore: SheetStore,
        userLocationStore: UserLocationStore,
        mapStore: MapStore,
        navigationStore: NavigationStore,
        routesPlanMapDrawer: RoutesPlanMapDrawer,
        destination: DestinationPointOfInterest
    ) {
        self.initialDestination = destination
        self.sheetStore = sheetStore
        self.mapStore = mapStore
        self.userLocationStore = userLocationStore
        self.navigationStore = navigationStore
        self.routesPlanMapDrawer = routesPlanMapDrawer
        Task {
            await self.fetchRoutePlanForFirstTime()
        }
        self.bindMapEvents()
    }

    // MARK: Functions

    func addNewRoute() {
        self.sheetStore.show(
            .navigationAddSearchView { [weak self] newDestination in
                guard let self, var routePlan else { return }
                routePlan.waypoints.append(RouteWaypoint(
                    type: .location(newDestination),
                    title: newDestination.title
                ))
                withAnimation {
                    self.routePlan = routePlan
                }
                self.updateHeight()
                Task {
                    await self.fetchRoutePlan(for: routePlan.waypoints)
                }
            }
        )
    }

    func startNavigation() {
        guard let selectedRoute = self.routePlan?.selectedRoute else { return }
        self.routesPlanMapDrawer.clear()
        AppEvents.publisher.send(.startNavigation(selectedRoute))
    }

    func swap() async {
        guard var routePlan, self.canSwap else { return }
        routePlan.waypoints.reverse()
        withAnimation {
            self.routePlan = routePlan
        }
        let destinations = routePlan.waypoints
        await self.fetchRoutePlan(for: destinations)
    }

    func remove(_ destination: RouteWaypoint) async {
        guard var routePlan else { return }
        routePlan.waypoints.removeAll(where: { $0 == destination })
        withAnimation {
            self.routePlan = routePlan
        }
        self.updateHeight()
        await self.fetchRoutePlan(for: routePlan.waypoints)
    }

    func moveDestinations(fromOffsets: IndexSet, toOffset: Int) async {
        guard var routePlan, self.canMove else { return }
        routePlan.waypoints.move(fromOffsets: fromOffsets, toOffset: toOffset)
        withAnimation {
            self.routePlan = routePlan
        }
        await self.fetchRoutePlan(for: routePlan.waypoints)
    }

    func cancel() {
        self.routesPlanMapDrawer.clear()
        self.sheetStore.popSheet()
    }

    func selectRoute(withID routeID: Int) {
        if var routePlan,
           let newSelectedRoute = routePlan.routes.first(where: { $0.id == routeID }) {
            routePlan.selectedRoute = newSelectedRoute
            withAnimation {
                self.routePlan = routePlan
            }
            self.drawRoutes(in: routePlan)
        }
    }
}

private extension RoutePlannerStore {
    func updateHeight() {
        let height: CGFloat
        if let routePlan {
            let buttonHeight: CGFloat = 56
            let listHeight = CGFloat(routePlan.waypoints.count) * self.rowHeight
            let addStopHeight = self.rowHeight
            let padding: CGFloat = 16
            height = buttonHeight + listHeight + addStopHeight + padding
        } else {
            height = 60
        }
        self.sheetContext?.detentData.value = DetentData(
            selectedDetent: .height(height),
            allowedDetents: [.height(height)]
        )
    }

    func bindMapDrawing(to sheetEventsPublisher: any Publisher<SheetEvent, Never>) {
        sheetEventsPublisher.sink { [weak self] event in
            guard let self else { return }
            switch event {
            case .willPresentOtherSheetOnTop, .willRemove:
                self.routeMapEventSubscription?.cancel()
                self.routesPlanMapDrawer.clear()
            case .willShow:
                guard let routePlan else { return }
                self.drawRoutes(in: routePlan)
                self.bindMapEvents()
            }
        }
        .store(in: &self.subscriptions)
    }

    func fetchRoutePlanForFirstTime() async {
        guard let userLocation = await self.userLocationStore.location(allowCached: false) else {
            self.routeFetchingError = .locationNotEnabled
            return
        }
        let initialDestinations: [RouteWaypoint] = [
            RouteWaypoint(
                type: .userLocation(Coordinates(
                    latitude: userLocation.coordinate.latitude,
                    longitude: userLocation.coordinate.longitude
                )),
                title: "User Location"
            ),
            RouteWaypoint(
                type: .location(self.initialDestination),
                title: self.initialDestination.title
            )
        ]
        await self.fetchRoutePlan(for: initialDestinations)
    }

    func fetchRoutePlan(for destinations: [RouteWaypoint]) async {
        self.isLoading = true
        self.updateHeight()
        defer { self.isLoading = false }

        guard destinations.count > 1 else {
            self.routeFetchingError = .errorFetchingRoute
            return
        }
        defer { self.updateHeight() }
        var waypoints = destinations.map { destination in
            let location = switch destination.type {
            case let .location(destinationItem):
                destinationItem.coordinate
            case let .userLocation(coordinates):
                coordinates.clLocationCoordinate2D
            }
            return Waypoint(
                coordinate: GeographicCoordinate(
                    cl: location
                ),
                kind: .break
            )
        }
        do {
            let fromWaypoint = waypoints.removeFirst()
            let destinationWaypoint = waypoints.removeLast()

            let routes = try await self.routePlanner.planRoutes(
                from: fromWaypoint,
                to: destinationWaypoint,
                waypoints: waypoints
            )
            guard let selectedRoute = routes.first else {
                throw RoutingError.routing(.noRoute(message: "No route found"))
            }
            let plan = RoutePlan(
                waypoints: destinations,
                routes: routes,
                selectedRoute: selectedRoute
            )
            withAnimation {
                self.routePlan = plan
            }
            self.drawRoutes(in: plan)
            self.updateHeight()
        } catch {
            self.routeFetchingError = .errorFetchingRoute
        }
    }

    func drawRoutes(in plan: RoutePlan) {
        guard !self.sheetContext.isNil else { return }
        self.routesPlanMapDrawer.drawRoutes(
            routes: plan.routes,
            selectedRoute: plan.selectedRoute,
            waypoints: plan.waypoints
        )
    }

    func bindMapEvents() {
        self.routeMapEventSubscription = self.routesPlanMapDrawer.routePlanEvents.sink { [weak self] event in
            guard let self else { return }
            switch event {
            case let .didSelectRoute(routeID):
                self.selectRoute(withID: routeID)
            }
        }
    }
}

// MARK: - Previewable

extension RoutePlannerStore: Previewable {
    static let storeSetUpForPreviewing = RoutePlannerStore(
        sheetStore: .storeSetUpForPreviewing,
        userLocationStore: .storeSetUpForPreviewing,
        mapStore: .storeSetUpForPreviewing,
        navigationStore: .storeSetUpForPreviewing,
        routesPlanMapDrawer: RoutesPlanMapDrawer(),
        destination: .artwork
    )
}
