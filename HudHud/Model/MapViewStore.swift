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

@MainActor @Observable
final class MapViewStore {

    // MARK: Properties

    let streetViewStore: StreetViewStore

    private let mapActionHandler: MapActionHandler
    private let mapStore: MapStore
    private let sheetStore: SheetStore
    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Lifecycle

    init(mapStore: MapStore, streetViewStore: StreetViewStore, sheetStore: SheetStore) {
        self.mapActionHandler = MapActionHandler(mapStore: mapStore, sheetStore: sheetStore)
        self.mapStore = mapStore
        self.streetViewStore = streetViewStore
        self.sheetStore = sheetStore
    }

    // MARK: Functions

    // MARK: - Internal

    func didTapOnMap(coordinates: CLLocationCoordinate2D, containing features: [any MLNFeature]) {
        if self.streetViewStore.streetViewScene != nil {
            // handle streetView tap
            Task {
                await self.streetViewStore.loadNearestStreetView(for: coordinates)
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

// MARK: - Previewable

extension MapViewStore: Previewable {
    static let storeSetUpForPreviewing = MapViewStore(mapStore: .storeSetUpForPreviewing, streetViewStore: .storeSetUpForPreviewing, sheetStore: .storeSetUpForPreviewing)
}
