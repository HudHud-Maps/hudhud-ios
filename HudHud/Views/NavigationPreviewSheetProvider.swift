//
//  NavigationPreviewSheetProvider.swift
//  HudHud
//
//  Created by Naif Alrashed on 10/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct NavigationPreviewSheetProvider: SheetProvider {

    // MARK: Properties

    let sheetStore: SheetStore
    let routingStore: RoutingStore

    // MARK: Content

    var sheetView: some View {
        NavigationSheetView(routingStore: self.routingStore, sheetStore: self.sheetStore)
    }

    var mapOverlayView: some View {
        EmptyView()
    }
}
