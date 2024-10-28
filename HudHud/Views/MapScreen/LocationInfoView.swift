//
//  LocationInfoView.swift
//  HudHud
//
//  Created by Ali Hilal on 26/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct LocationInfoView: View {

    // MARK: Properties

    let isNavigating: Bool
    let label: String

    // MARK: Content

    var body: some View {
        if self.isNavigating {
            Text(self.label)
                .font(.caption)
                .padding(.all, 8)
                .foregroundColor(.white)
                .background(
                    Color.black.opacity(0.7)
                        .clipShape(.buttonBorder, style: FillStyle())
                )
        }
    }
}
