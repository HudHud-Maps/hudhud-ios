//
//  NavigationMapViewModifiers.swift
//  HudHud
//
//  Created by Ali Hilal on 03.11.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SwiftUI

public extension NavigationMapView {
    /// Set the MapView's content inset. See ``NavigationMapViewContentInsetMode`` for static and dynamic options.
    ///
    /// This functionality is used to position the navigation puck/user location in the map view
    ///
    /// - Parameter inset: The inset mode for the navigation map view
    /// - Returns: The modified NavigationMapView
    func navigationMapViewContentInset(_ inset: NavigationMapViewContentInsetMode) -> NavigationMapView {
        var newNavigationMapView = self
        newNavigationMapView.mapViewContentInset = inset.uiEdgeInsets
        return newNavigationMapView
    }
}
