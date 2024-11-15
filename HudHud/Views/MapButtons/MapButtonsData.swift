//
//  MapButtonsData.swift
//  HudHud
//
//  Created by Alaa . on 03/03/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SFSafeSymbols

struct MapButtonData: Identifiable, Equatable {

    // MARK: Nested Types

    enum IconStyle {
        case icon(SFSymbol)
        case text(String)
    }

    // MARK: Properties

    let id = UUID()
    var sfSymbol: IconStyle
    let action: () -> Void

    // MARK: Static Functions

    // MARK: - Internal

    static func == (lhs: MapButtonData, rhs: MapButtonData) -> Bool {
        return lhs.id == rhs.id
    }

    @MainActor static func buttonIcon(for mode: SearchViewStore.Mode) -> MapButtonData.IconStyle {
        switch mode {
        case .live(.apple):
            .icon(.appleLogo)
        case .preview:
            .icon(.pCircle)
        case .live(provider: .hudhud):
            .icon(.bird)
        }
    }
}
