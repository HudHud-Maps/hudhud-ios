//
//  MapViewStore.swift
//  HudHud
//
//  Created by Naif Alrashed on 06/07/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import MapLibre

// MARK: - MapViewStore

@MainActor
class MapViewStore: ObservableObject {

    // MARK: Properties

    private let mapActionHandler: MapActionHandler

    // MARK: Lifecycle

    init(mapStore: MapStore) {
        self.mapActionHandler = MapActionHandler(mapStore: mapStore)
    }

    // MARK: Functions

    // MARK: - Internal

    func didTapOnMap(containing features: [any MLNFeature]) {
        self.mapActionHandler.didTapOnMap(containing: features)
    }
}
