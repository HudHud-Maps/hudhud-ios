//
//  RoutePlannerView.swift
//  HudHud
//
//  Created by Naif Alrashed on 30/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import SwiftUI

// MARK: - RouteWaypoint

struct RouteWaypoint: Hashable {

    // MARK: Nested Types

    enum RouteWaypointType: Hashable {
        case userLocation
        case location(ResolvedItem)
    }

    // MARK: Properties

    let type: RouteWaypointType
    let title: String
}

// MARK: - RoutePlannerView

struct RoutePlannerView: View {

    // MARK: Properties

    @State var routePlannerStore: RoutePlannerStore

    // MARK: Content

    var body: some View {
        Group {
            switch self.routePlannerStore.state {
            case .initialLoading, .errorFetchignRoute, .locationNotEnabled:
                ProgressView()
            case let .loaded(plan):
                RoutePlanView(destinations: plan.waypoints)
            }
        }
        .onAppear {
            self.routePlannerStore.onAppear()
        }
    }
}

// MARK: - RoutePlanView

struct RoutePlanView: View {

    // MARK: Properties

    let destinations: [RouteWaypoint]

    // MARK: Content

    var body: some View {
        VStack(alignment: .locationIconCenterAlignment) {
            ForEach(self.destinations, id: \.self) { destination in
                RoutePlannerRow(destination: destination)
            }
        }
    }
}

// MARK: - RoutePlannerRow

struct RoutePlannerRow: View {

    // MARK: Properties

    let destination: RouteWaypoint

    // MARK: Content

    var body: some View {
        VStack(alignment: .locationIconCenterAlignment, spacing: 6) {
            Label {
                HStack {
                    Text(self.destination.title)
                        .hudhudFontStyle(.labelMedium)
                        .foregroundStyle(Color.Colors.General._01Black)
                    Spacer()
                }
            } icon: {
                DestinationImage(destinationType: self.destination.type)
                    .alignmentGuide(.locationIconCenterAlignment) { $0[HorizontalAlignment.center] }
            }
            Label {
                Rectangle()
                    .fill(Color.black.opacity(0.1))
                    .frame(width: .infinity, height: 1)
                    .overlay(alignment: .trailing) {
                        Image(.swapIcon)
                            .padding(6)
                            .background(Circle().fill(Color(red: 242 / 255, green: 242 / 255, blue: 242 / 255)))
                            .padding(.trailing)
                    }
            } icon: {
                VStack(spacing: 4) {
                    Circle()
                        .fill(Color.black.opacity(0.1))
                        .frame(width: 4, height: 4)
                    Circle()
                        .fill(Color.black.opacity(0.1))
                        .frame(width: 4, height: 4)
                    Circle()
                        .fill(Color.black.opacity(0.1))
                        .frame(width: 4, height: 4)
                }
                .alignmentGuide(.locationIconCenterAlignment) { $0[HorizontalAlignment.center] }
            }
        }
        .padding(.leading)
    }
}

// MARK: - DestinationImage

struct DestinationImage: View {

    // MARK: Properties

    let destinationType: RouteWaypoint.RouteWaypointType

    // MARK: Content

    var body: some View {
        switch self.destinationType {
        case .userLocation:
            Image(.userPuck)
        case let .location(item):
            Image(systemSymbol: item.symbol)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 12, height: 12)
                .foregroundStyle(.white)
                .padding(6)
                .clipShape(Circle())
                .overlay(Circle().stroke(.tertiary, lineWidth: 0.5))
                .layoutPriority(1)
                .background(
                    item.color.mask(Circle())
                )
        }
    }
}

private extension HorizontalAlignment {
    private enum LocationIconCenterAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[HorizontalAlignment.center]
        }
    }

    static let locationIconCenterAlignment = HorizontalAlignment(LocationIconCenterAlignment.self)
}

#Preview {
    RoutePlannerView(routePlannerStore: .storeSetUpForPreviewing)
}
