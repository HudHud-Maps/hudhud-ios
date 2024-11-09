//
//  NavigationControls.swift
//  HudHud
//
//  Created by Ali Hilal on 07/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

// MARK: - NavigationControls

struct NavigationControls: View {

    // MARK: Properties

    let isCompact: Bool

    let onAction: (ActiveTripInfoViewAction) -> Void

    // MARK: Content

    var body: some View {
        HStack(spacing: 16) {
            RoutePreviewButton {
                self.onAction(.switchToRoutePreviewMode)
            }

            FinishButton(isCompact: self.isCompact) {
                self.onAction(.exitNavigation)
            }
        }
    }
}

// MARK: - RoutePreviewButton

private struct RoutePreviewButton: View {

    // MARK: Properties

    let onTap: () -> Void

    // MARK: Content

    var body: some View {
        Button(action: {
            self.onTap()
        }) {
            Image(.routePreviewIcon)
                .frame(width: 56, height: 56)
                .background(Color.Colors.General._03LightGrey)
                .clipShape(Circle())
        }
        .accessibilityLabel("Preview Route")
    }
}

// MARK: - FinishButton

private struct FinishButton: View {

    // MARK: Properties

    let isCompact: Bool

    let action: () -> Void

    // MARK: Content

    var body: some View {
        Button(action: {
            self.action()
        }) {
            Text("Finish")
                .hudhudFont(.callout)
                .fontWeight(.semibold)
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(height: 56)
                .frame(maxWidth: self.isCompact ? nil : .infinity)
                .background(Color.Colors.General._03LightGrey)
                .clipShape(Capsule())
        }
    }
}
