//
//  RoutePlannerSheetProvider.swift
//  HudHud
//
//  Created by Naif Alrashed on 10/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct RoutePlannerSheetProvider: SheetProvider {

    // MARK: Properties

    let routePlannerStore: RoutePlannerStore

    // MARK: Content

    var sheetView: some View {
        RoutePlannerView(routePlannerStore: self.routePlannerStore)
    }

    var mapOverlayView: some View {
        EmptyView()
    }
}
