//
//  MapViewStore.swift
//  HudHud
//
//  Created by Naif Alrashed on 06/07/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import Combine
import FerrostarCoreFFI
import MapLibre
import NavigationTransition
import OSLog
import SwiftUI

// MARK: - MapViewStore

@MainActor @Observable
final class MapViewStore {

    // MARK: Properties

    var streetViewStore: StreetViewStore?

    private let mapActionHandler: MapActionHandler
    private let routingStore: RoutingStore
    private let mapStore: MapStore
    private let sheetStore: SheetStore
    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Lifecycle

    init(mapStore: MapStore, routingStore: RoutingStore, sheetStore: SheetStore) {
        self.mapActionHandler = MapActionHandler(mapStore: mapStore)
        self.mapStore = mapStore
        self.routingStore = routingStore
        self.sheetStore = sheetStore

        self.showPotentialRouteWhenAvailable()
        self.showSelectedDetentWhenSelectingAnItem()
    }

    // MARK: Functions

    // MARK: - Internal

    func didTapOnMap(coordinates: CLLocationCoordinate2D, containing features: [any MLNFeature]) {
        if self.streetViewStore?.streetViewScene != nil {
            // handle streetView tap
            Task {
                await self.streetViewStore?.loadNearestStreetView(for: coordinates)
            }
            return
        }

        let didHaveAnAction = self.mapActionHandler.didTapOnMap(containing: features)
        if !didHaveAnAction {
            // user tapped nothing - deselect
            Logger.mapInteraction.debug("Tapped nothing - setting to nil...")
            self.sheetStore.popSheet()
            self.mapStore.unselectItem()
        }
    }
}

private extension MapViewStore {

    func showPotentialRouteWhenAvailable() {
        self.routingStore.$potentialRoute // is it meant to be the selcted route?
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] newPotentialRoute in
                guard let self else { return }

                if let newPotentialRoute, case .pointOfInterest = self.sheetStore.currentSheet?.viewData {
                    self.sheetStore.pushSheet(SheetViewData(viewData: .navigationPreview))
                    self.mapStore.updateCamera(state: .route(newPotentialRoute))
                } else if self.sheetStore.currentSheet?.viewData == .navigationPreview, newPotentialRoute == nil {
                    self.sheetStore.popSheet()
                    self.routingStore.reset()
                }
            }
            .store(in: &self.subscriptions)
    }

    func showSelectedDetentWhenSelectingAnItem() {
        self.mapStore.selectedItem
            .compactMap { $0 }
            .sink { [weak self] selectedItem in
                guard let self, self.routingStore.potentialRoute == nil else {
                    return
                }
                if case let .pointOfInterest(item) = self.sheetStore.currentSheet?.viewData {
                    self.sheetStore.sheets[self.sheetStore.sheets.count - 1] = SheetViewData(viewData: .pointOfInterest(item))
                } else {
                    self.sheetStore.pushSheet(SheetViewData(viewData: .pointOfInterest(selectedItem)))
                }
            }
            .store(in: &self.subscriptions)
    }
}

// MARK: - Previewable

extension MapViewStore: Previewable {
    static let storeSetUpForPreviewing = MapViewStore(mapStore: .storeSetUpForPreviewing, routingStore: .storeSetUpForPreviewing, sheetStore: .storeSetUpForPreviewing)
}
