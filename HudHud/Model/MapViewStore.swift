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

@MainActor
final class MapViewStore: ObservableObject {

    // MARK: Properties

    @ObservedObjectChild var navigationVisualization: NavigationVisualization

    private let mapActionHandler: MapActionHandler

    @ObservedObjectChild private var mapStore: MapStore

    private var sheetStore: SheetStore

    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Lifecycle

    init(
        mapStore: MapStore,
        navigationVisualization: NavigationVisualization,
        sheetStore: SheetStore
    ) {
        self.mapActionHandler = MapActionHandler(mapStore: mapStore)
        self.mapStore = mapStore
        self.navigationVisualization = navigationVisualization
        self.sheetStore = sheetStore
        self.showPotentialRouteWhenAvailable()
        self.showSelectedDetentWhenSelectingAnItem()
    }

    // MARK: Functions

    // MARK: - Internal

    func didTapOnMap(containing features: [any MLNFeature]) {
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
        self.navigationVisualization.$routes
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] routes in
                guard let self else { return }
                let newPotentialRoute = routes.first
                if let newPotentialRoute, case .pointOfInterest = self.sheetStore.currentSheet?.viewData {
                    self.sheetStore.pushSheet(SheetViewData(viewData: .navigationPreview))
                    self.mapStore.updateCamera(state: .route(newPotentialRoute))
                } else if self.sheetStore.currentSheet?.viewData == .navigationPreview, newPotentialRoute == nil {
                    self.sheetStore.popSheet()
                }
            }
            .store(in: &self.subscriptions)
    }

    func showSelectedDetentWhenSelectingAnItem() {
        self.mapStore.$selectedItem
            .compactMap { $0 }
            .sink { [weak self] selectedItem in
                guard let self, self.navigationVisualization.routes.isEmpty else {
                    return
                }
                if case let .pointOfInterest(item) = self.sheetStore.currentSheet?.viewData {
                    self.sheetStore.sheets[self.sheetStore.sheets.count - 1] = SheetViewData(viewData: .pointOfInterest(selectedItem))
                } else {
                    self.sheetStore.pushSheet(SheetViewData(viewData: .pointOfInterest(selectedItem)))
                }
            }
            .store(in: &self.subscriptions)
    }
}

// MARK: - Previewable

extension MapViewStore: Previewable {
    static let storeSetUpForPreviewing = MapViewStore(
        mapStore: .storeSetUpForPreviewing,
        navigationVisualization: .preview,
        sheetStore: .storeSetUpForPreviewing
    )
}
