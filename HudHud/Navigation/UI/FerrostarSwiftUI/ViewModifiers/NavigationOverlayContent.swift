//
//  NavigationOverlayContent.swift
//  HudHud
//
//  Created by Ali Hilal on 07/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - NavigationOverlayContent

public protocol NavigationOverlayContent: View {
    var overlayStore: OverlayContentStore { get }
}

// MARK: - OverlayContentStore

@Observable
public class OverlayContentStore: ObservableObject {
    var content: [NavigationOverlayZone: () -> AnyView] = [:]
}

public extension NavigationOverlayContent {
    func withNavigationOverlay(
        _ zone: NavigationOverlayZone,
        @ViewBuilder content: @escaping () -> some View
    ) -> Self {
        let newSelf = self
        newSelf.overlayStore.content[zone] = { AnyView(content()) }
        return newSelf
    }
}
