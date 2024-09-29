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
import OSLog
import SwiftUI

// MARK: - MapViewStore

@MainActor
final class MapViewStore: ObservableObject {

    // MARK: Properties

    private let mapActionHandler: MapActionHandler
    private let routingStore: RoutingStore
    private let mapStore: MapStore

    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Computed Properties

    @Published var sheetState = SheetState() {
        didSet {
            Task {
                await temporarilyAddLastSelectedDetentIfPopNavigationHappened(
                    previousSheetState: oldValue
                )
            }
        }
    }

    // MARK: Lifecycle

    init(mapStore: MapStore, routingStore: RoutingStore) {
        self.mapActionHandler = MapActionHandler(mapStore: mapStore)
        self.mapStore = mapStore
        self.routingStore = routingStore
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
            if !self.sheetState.sheets.isEmpty {
                self.sheetState.sheets.removeLast()
            }
            self.mapStore.selectedItem = nil
        }
    }

    func reset() {
        self.resetAllowedDetents()
        self.sheetState.selectedDetent = .small
        if !self.sheetState.sheets.isEmpty {
            self.sheetState.sheets.removeLast()
        }
    }

    func resetAllowedDetents() {
        self.sheetState.allowedDetents = [.small, .medium, .large]
    }

    func show(fullSheet: SheetViewData) async {
        self.sheetState.previousSheetSelectedDetent = self.sheetState.selectedDetent
        self.sheetState.sheets.append(fullSheet)
        try? await Task.sleep(nanoseconds: 4000)
        self.sheetState.previousSheetSelectedDetent = nil
    }

}

private extension MapViewStore {
    func showPotentialRouteWhenAvailable() {
        self.routingStore.$potentialRoute
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] newPotentialRoute in
                guard let self else { return }

                if let newPotentialRoute, case .pointOfInterest = self.sheetState.sheets.last?.viewData {
                    self.sheetState.sheets.append(SheetViewData(viewData: .navigationPreview))
                    self.mapStore.updateCamera(state: .route(newPotentialRoute))
                } else if self.sheetState.sheets.last?.viewData == .navigationPreview, newPotentialRoute == nil {
                    self.sheetState.sheets.removeLast()
                }
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
                if !self.sheetState.sheets.isEmpty {
                    self.sheetState.sheets.removeLast()
                }
                self.sheetState.sheets.append(SheetViewData(viewData: .pointOfInterest(selectedItem)))
            }
            .store(in: &self.subscriptions)
    }

    // needed to fix animation glitch
    func temporarilyAddLastSelectedDetentIfPopNavigationHappened(previousSheetState: SheetState) async {
        guard self.sheetState.sheets.count != previousSheetState.sheets.count else {
            return
        }
        self.sheetState.previousSheetSelectedDetent = previousSheetState.selectedDetent
        try? await Task.sleep(nanoseconds: 250 * NSEC_PER_MSEC)
        self.sheetState.previousSheetSelectedDetent = nil
    }
}

// MARK: - Previewable

extension MapViewStore: Previewable {
    static let storeSetUpForPreviewing = MapViewStore(
        mapStore: .storeSetUpForPreviewing,
        routingStore: .storeSetUpForPreviewing
    )
}
