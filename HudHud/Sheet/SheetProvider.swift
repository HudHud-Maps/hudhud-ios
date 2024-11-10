//
//  SheetProvider.swift
//  HudHud
//
//  Created by Naif Alrashed on 08/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

protocol SheetProvider {
    associatedtype SheetView: View
    associatedtype MapOverlayView: View

    @ViewBuilder var sheetView: SheetView { get }
    @ViewBuilder var mapOverlayView: MapOverlayView { get }
}
