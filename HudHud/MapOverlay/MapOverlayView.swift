//
//  MapOverlayView.swift
//  HudHud
//
//  Created by Naif Alrashed on 08/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Combine
import SwiftUI

// MARK: - MapOverlayView

struct MapOverlayView: View {

    // MARK: Properties

    @State var mapOverlayStore: MapOverlayStore

    // MARK: Content

    var body: some View {
        self.mapOverlayStore.currentOverlay
    }
}

#Preview {
    MapOverlayView(mapOverlayStore: .storeSetUpForPreviewing)
}
