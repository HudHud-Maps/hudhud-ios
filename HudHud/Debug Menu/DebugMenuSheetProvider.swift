//
//  DebugMenuSheetProvider.swift
//  HudHud
//
//  Created by Naif Alrashed on 10/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct DebugMenuSheetProvider: SheetProvider {

    // MARK: Properties

    let debugStore: DebugStore
    let sheetStore: SheetStore

    // MARK: Content

    var sheetView: some View {
        DebugMenuView(
            debugSettings: self.debugStore,
            sheetStore: self.sheetStore
        )
    }

    var mapOverlayView: some View {
        EmptyView()
    }
}
