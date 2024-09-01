//
//  MapViewStore.swift
//  HudHud
//
//  Created by Naif Alrashed on 06/07/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import Combine
import MapLibre
import OSLog
import SwiftUI

// MARK: - MapViewStore

@MainActor
final class MapViewStore: ObservableObject {

    // MARK: Properties

    @Published var path = NavigationPath()

    private let mapActionHandler: MapActionHandler
    private let routingStore: RoutingStore
    private let mapStore: MapStore

    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Lifecycle

    init(mapStore: MapStore, routingStore: RoutingStore) {
        self.mapActionHandler = MapActionHandler(mapStore: mapStore)
        self.mapStore = mapStore
        self.routingStore = routingStore
        self.showPotentialRouteWhenAvailable()
        self.updateDetentWhenStartingNavigation()
        self.showSelectedDetentWhenSelectingAnItem()
    }

    // MARK: Functions

    // MARK: - Internal

    func didTapOnMap(containing features: [any MLNFeature]) {
        let didHaveAnAction = self.mapActionHandler.didTapOnMap(containing: features)
        if !didHaveAnAction {
            // user tapped nothing - deselect
            Logger.mapInteraction.debug("Tapped nothing - setting to nil...")
            if !self.path.isEmpty {
                self.path.removeLast()
            }
            self.mapStore.selectedItem = nil
        }
    }
}

private extension MapViewStore {
    func showPotentialRouteWhenAvailable() {
        self.routingStore.$potentialRoute
            .compactMap { $0 }
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] newPotentialRoute in
                guard let self,
                      self.path.contains(RoutingService.RouteCalculationResult.self) == false else { return }
                self.path.append(newPotentialRoute)
                self.mapStore.updateCamera(state: .route(newPotentialRoute))
            }
            .store(in: &self.subscriptions)
    }

    func updateDetentWhenStartingNavigation() {
        self.routingStore.$navigatingRoute.sink { [weak self] _ in
            guard let self, let elements = try? self.path.elements() else { return }
            self.mapStore.updateSelectedSheetDetent(to: elements.last)
        }
        .store(in: &self.subscriptions)
    }

    func showSelectedDetentWhenSelectingAnItem() {
        self.mapStore.$selectedItem
            .compactMap { $0 }
            .sink { [weak self] selectedItem in
                guard let self, self.routingStore.potentialRoute == nil else {
                    return
                }
                if !self.path.isEmpty {
                    self.path.removeLast()
                }
                self.path.append(selectedItem)
            }
            .store(in: &self.subscriptions)
    }
}

// MARK: - Previewable

extension MapViewStore: Previewable {
    static let storeSetUpForPreviewing = MapViewStore(
        mapStore: .storeSetUpForPreviewing,
        routingStore: .storeSetUpForPreviewing
    )
}
