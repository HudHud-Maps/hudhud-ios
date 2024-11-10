//
//  MapOverlayStore.swift
//  HudHud
//
//  Created by Naif Alrashed on 10/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Combine
import SwiftUI

// MARK: - MapOverlayStore

@Observable
@MainActor
final class MapOverlayStore {

    // MARK: Properties

    private(set) var currentOverlay: AnyView

    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Lifecycle

    init(sheetStore: SheetStore) {
        self.currentOverlay = AnyView(sheetStore.currentSheet.sheetProvider.mapOverlayView)
        sheetStore.navigationCommands
            .map(\.sheetData)
            .sink { [weak self] sheetData in
                self?.currentOverlay = AnyView(sheetData.sheetProvider.mapOverlayView)
            }
            .store(in: &self.subscriptions)
    }
}

// MARK: - Previewable

extension MapOverlayStore: Previewable {
    static let storeSetUpForPreviewing = MapOverlayStore(sheetStore: .storeSetUpForPreviewing)
}
