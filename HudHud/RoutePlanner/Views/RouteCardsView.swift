//
//  RouteCardsView.swift
//  HudHud
//
//  Created by Naif Alrashed on 12/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import FerrostarCoreFFI
import SwiftUI

// MARK: - RouteCardsView

struct RouteCardsView: View {

    // MARK: Properties

    let routes: [RouteViewData]
    @Binding var selectedRoute: Int?

    // MARK: Content

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(self.routes) { route in
                        RouteCardView(route: route)
                            .padding(self.routeCardPadding(for: route))
                            .frame(width: self.routeCardWidth(using: geometry))
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: self.$selectedRoute)
        }
        .frame(height: 80)
    }

    // MARK: Functions

    func routeCardPadding(for route: RouteViewData) -> Edge.Set {
        if self.routes.count <= 1 {
            .horizontal
        } else if self.routes.last == route {
            .horizontal
        } else {
            .leading
        }
    }

    func routeCardWidth(using geometry: GeometryProxy) -> CGFloat {
        if self.routes.count > 1 {
            return geometry.frame(in: .global).width - 50
        } else {
            return geometry.frame(in: .global).width
        }
    }
}

// MARK: - RouteCardView

struct RouteCardView: View {

    // MARK: Properties

    let route: RouteViewData

    // MARK: Content

    var body: some View {
        VStack {
            HStack {
                Text(self.route.duration)
                    .foregroundStyle(Color.Colors.General._01Black)
                    .hudhudFontStyle(.headingXlarge)
                Spacer()
                Text(self.route.distance)
                    .foregroundStyle(Color.Colors.General._02Grey)
                    .hudhudFontStyle(.paragraphMedium)
            }
            HStack(spacing: .zero) {
                Text(self.route.summary)
                    .foregroundStyle(Color.Colors.General._02Grey)
                    .hudhudFontStyle(.paragraphMedium)
                Spacer()
            }
        }
        .padding()
        .background(.white)
        .clipShape(
            RoundedRectangle(cornerSize: CGSize(width: 12, height: 3), style: .circular)
        )
    }
}
