//
//  RouteCardsView.swift
//  HudHud
//
//  Created by Naif Alrashed on 12/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import FerrostarCoreFFI
import SwiftUI

// MARK: - RouteViewData

struct RouteViewData: Hashable, Identifiable {
    let id: Int
    let distance: String
    let duration: String
    let summary: String
}

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
        .cornerRadius(16)
    }
}

#Preview {
    @Previewable @State var selectedRoute: Int?
    let routes: [RouteViewData] = [
        RouteViewData(id: 1, distance: "20 km", duration: "50 mins", summary: "some summary"),
        RouteViewData(id: 2, distance: "30 km", duration: "60 mins", summary: "some summary"),
        RouteViewData(id: 3, distance: "15 km", duration: "30 mins", summary: "some summary")
    ]
    RouteCardsView(routes: routes, selectedRoute: $selectedRoute)
}
