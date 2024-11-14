//
//  LoginToSavePOISheetProvider.swift
//  HudHud
//
//  Created by Naif Alrashed on 12/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct LoginToSavePOISheetProvider: SheetProvider {

    // MARK: Properties

    let sheetStore: SheetStore

    // MARK: Content

    var sheetView: some View {
        LoginToSavePOIView(sheetStore: self.sheetStore)
    }

    var mapOverlayView: some View {
        EmptyView()
    }
}
