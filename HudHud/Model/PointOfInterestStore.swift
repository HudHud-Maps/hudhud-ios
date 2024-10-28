//
//  PointOfInterestStore.swift
//  HudHud
//
//  Created by Naif Alrashed on 23/04/1446 AH.
//  Copyright © 1446 AH HudHud. All rights reserved.
//

import BackendService
import Foundation

@Observable
@MainActor
final class PointOfInterestStore {

    // MARK: Properties

    private(set) var pointOfInterest: ResolvedItem

    private let mapStore: MapStore
    private let sheetStore: SheetStore
    private let hudhudResolver = HudHudPOI(transport: transport)

    // MARK: Lifecycle

    init(pointOfInterest: ResolvedItem, mapStore: MapStore, sheetStore: SheetStore) {
        self.pointOfInterest = pointOfInterest
        self.mapStore = mapStore
        self.sheetStore = sheetStore
        Task {
            await self.refreshPointOfInterest()
        }
    }

    // MARK: Functions

    func reApplyThePointOfInterestToTheMapIfNeeded() {
        self.mapStore.show(self.pointOfInterest, shouldFocusCamera: true)
    }

    func goToDirections() {
        self.sheetStore.show(.navigationPreview)
    }

    private func refreshPointOfInterest() async {
        guard var detailedPointOfInterest = try? await hudhudResolver.lookup(
            id: self.pointOfInterest.id,
            baseURL: DebugStore().baseURL
        ) else { return }
        detailedPointOfInterest.systemColor = self.pointOfInterest.systemColor
        detailedPointOfInterest.symbol = self.pointOfInterest.symbol
        self.pointOfInterest = detailedPointOfInterest
    }
}
