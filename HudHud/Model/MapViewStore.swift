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
@Observable
final class MapViewStore {

    // MARK: Properties

    private let mapActionHandler: MapActionHandler
    private let routingStore: RoutingStore
    private let mapStore: MapStore

    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Computed Properties

    var sheets: [SheetViewData] {
        get {
            self.sheetState.sheets
        }
        set {
            Task {
                await self.setNewSheetsInAnAnimationFriendlyWay(newSheets: newValue)
            }
        }
    }

    var selectedDetent: PresentationDetent {
        get {
            self.sheetState.selectedDetent
        }

        set {
            self.sheetState.selectedDetent = newValue
        }
    }

    var allowedDetents: Set<PresentationDetent> {
        get {
            self.sheetState.allowedDetents
        }

        set {
            self.sheetState.allowedDetents = newValue
        }
    }

    private var sheetState = SheetState() {
        didSet {
            Task {
                await self.temporarilyAddLastSelectedDetent(
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
        self.sheetState = SheetState()
    }

    // we do this to fix UI transition glitches
    // the way the fix happens is by adding the new sheet's selected detent to
    // the current selected & allowed detents, then wait for 100 ms
    // the current selected & allowed detents, then wait for a little bit
    // then apply the sheet transition
    func setNewSheetsInAnAnimationFriendlyWay(newSheets: [SheetViewData]) async {
        guard self.sheetState.sheets.count != newSheets.count else {
            self.sheetState.sheets = newSheets
            return
        }
        self.sheetState.newSheetSelectedDetent = newSheets.last?.selectedDetent ?? self.sheetState.emptySheetSelectedDetent
        try? await Task.sleep(nanoseconds: 100 * NSEC_PER_MSEC)
        self.sheetState.sheets = newSheets
        self.sheetState.newSheetSelectedDetent = nil
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
                if !self.sheets.isEmpty {
                    self.sheets.removeLast()
                }
                self.sheets.append(SheetViewData(viewData: .pointOfInterest(selectedItem)))
            }
            .store(in: &self.subscriptions)
    }

    // needed to fix animation jumping sheet when transitioning
    func temporarilyAddLastSelectedDetent(previousSheetState: SheetState) async {
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
