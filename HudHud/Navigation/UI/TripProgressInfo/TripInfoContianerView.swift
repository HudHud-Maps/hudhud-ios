//
//  TripInfoContianerView.swift
//  HudHud
//
//  Created by Ali Hilal on 09/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

// MARK: - ActiveTripInfoViewAction

enum ActiveTripInfoViewAction {
    case exitNavigation
    case switchToRoutePreviewMode
    case openNavigationSettings
}

// MARK: - TripInfoContianerView

struct TripInfoContianerView: View {

    // MARK: Properties

    let tripProgress: TripProgress
    let navigationAlert: NavigationAlert?

    let onAction: (ActiveTripInfoViewAction) -> Void

    @State var isExpanded: Bool = false

    @State private var dragOffset: CGFloat = 0
    @Environment(\.safeAreaInsets) private var safeAreaInsets

    // MARK: Content

    var body: some View {
        ZStack(alignment: .bottom) {
            self.content()
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                        .ignoresSafeArea()
                }
                .animation(.interpolatingSpring(stiffness: 300, damping: 30), value: self.isExpanded)
                .gesture(DragGesture(minimumDistance: 5, coordinateSpace: .local)
                    .onChanged { value in
                        withAnimation(.interactiveSpring()) {
                            self.dragOffset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                            let translation = value.translation.height
                            let velocity = value.predictedEndLocation.y - value.location.y

                            if abs(velocity) > 100 {
                                self.isExpanded = velocity < 0
                            } else if abs(translation) > 30 {
                                self.isExpanded = translation < 0
                            }

                            self.dragOffset = 0
                        }
                    })
        }
    }
}

private extension TripInfoContianerView {

    @ViewBuilder
    func content() -> some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.Colors.General._02Grey.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 12)
            if let navigationAlert {
                AlertView(tripProgress: self.tripProgress, info: navigationAlert, isExpanded: self.isExpanded, onAction: self.onAction)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .padding(.bottom, self.safeAreaInsets.bottom)
            } else {
                TripProgressView(tripProgress: self.tripProgress, isExpanded: self.isExpanded, onAction: self.onAction)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .padding(.bottom, self.safeAreaInsets.bottom)
            }
        }
    }
}
