//
//  PointOfInterestSheetProvider.swift
//  HudHud
//
//  Created by Naif Alrashed on 10/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import OSLog
import SwiftUI

struct PointOfInterestSheetProvider: SheetProvider {

    // MARK: Properties

    let pointOfInterest: ResolvedItem
    let mapStore: MapStore
    let sheetStore: SheetStore
    let routingStore: RoutingStore
    let userLocationStore: UserLocationStore
    let debugStore: DebugStore
    let routePlannerStore: RoutePlannerStore
    let favoritesStore: FavoritesStore

    @Feature(.enableNewRoutePlanner, defaultValue: false) private var enableNewRoutePlanner: Bool

    // MARK: Content

    var sheetView: some View {
        POIDetailSheet(pointOfInterestStore: PointOfInterestStore(pointOfInterest: self.pointOfInterest,
                                                                  mapStore: self.mapStore,
                                                                  sheetStore: self.sheetStore),
                       sheetStore: self.sheetStore,
                       favoritesStore: self.favoritesStore,
                       routingStore: self.routingStore,
                       didDenyLocationPermission: self.userLocationStore.permissionStatus.didDenyLocationPermission) { routeIfAvailable in
            Logger.searchView.info("Start item \(self.pointOfInterest)")
            if self.enableNewRoutePlanner {
                self.sheetStore.show(.routePlanner(self.routePlannerStore))
                return
            }
            Task {
                do {
                    try await self.routingStore.showRoutes(to: self.pointOfInterest,
                                                           with: routeIfAvailable)
                    self.sheetStore.show(.navigationPreview)
                } catch {
                    Logger.routing.error("Error navigating to \(self.pointOfInterest): \(error)")
                }
            }
        } onDismiss: {
            self.mapStore.clearItems(clearResults: false)
            self.sheetStore.popSheet()
        }
    }

    var mapOverlayView: some View {
        EmptyView()
    }
}
