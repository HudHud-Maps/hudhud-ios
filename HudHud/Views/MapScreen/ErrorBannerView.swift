//
//  ErrorBannerView.swift
//  HudHud
//
//  Created by Ali Hilal on 26/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import FerrostarCore
import FerrostarCoreFFI
import FerrostarMapLibreUI
import FerrostarSwiftUI
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import SwiftUI

// MARK: - ErrorBannerView

struct ErrorBannerView: View {

    // MARK: Properties

    @Binding var errorMessage: String?

    // MARK: Content

    var body: some View {
        if let errorMessage {
            NavigationUIBanner(severity: .error) {
                Text(errorMessage)
            }
            .onTapGesture { self.errorMessage = nil }
        }
    }
}
