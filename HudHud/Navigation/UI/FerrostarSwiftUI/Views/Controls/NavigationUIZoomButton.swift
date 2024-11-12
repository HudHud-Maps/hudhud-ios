//
//  NavigationUIZoomButton.swift
//  HudHud
//
//  Created by Ali Hilal on 03.11.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

public struct NavigationUIZoomButton: View {

    // MARK: Properties

    let onZoomIn: () -> Void
    let onZoomOut: () -> Void

    // MARK: Content

    public var body: some View {
        VStack(spacing: 0) {
            Button(
                action: self.onZoomIn,
                label: {
                    Image(systemSymbol: .plus)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 18, height: 18)
                }
            )
            .padding()

            Divider()
                .frame(width: 52)

            Button(
                action: self.onZoomOut,
                label: {
                    Image(systemSymbol: .minus)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 18, height: 18)
                }
            )
            .padding()
        }
        .foregroundColor(.primary)
        .background(Color(.systemBackground))
        .clipShape(Capsule())
    }
}

#Preview {
    VStack {
        NavigationUIZoomButton(
            onZoomIn: {},
            onZoomOut: {}
        )
    }
    .padding()
    .background(Color.green)
}
