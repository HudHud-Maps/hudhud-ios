//
//  MapLayersSheetProvider.swift
//  HudHud
//
//  Created by Naif Alrashed on 10/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import SwiftUI

struct MapLayersSheetProvider: SheetProvider {

    // MARK: Properties

    let mapStore: MapStore
    let sheetStore: SheetStore
    let hudhudMapLayerStore: HudHudMapLayerStore

    // MARK: Content

    var sheetView: some View {
        MapLayersView(
            mapStore: self.mapStore,
            sheetStore: self.sheetStore,
            hudhudMapLayerStore: self.hudhudMapLayerStore
        )
    }

    var mapOverlayView: some View {
        EmptyView()
    }
}
