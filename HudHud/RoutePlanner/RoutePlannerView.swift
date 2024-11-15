//
//  RoutePlannerView.swift
//  HudHud
//
//  Created by Naif Alrashed on 30/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import OSLog
import SwiftUI

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
            case .loaded:
                RoutePlanView(routePlannderStore: self.routePlannerStore)
            }
        }
        .padding(.vertical)
        .padding(.top)
        .background {
            /// according to the design the sheet height must match the view's height
            /// so we compute the height and report it to the sheet to adjust its height
            GeometryReader { geometry in
                Color.clear.onAppear {
                    self.routePlannerStore.didChangeHeight(to: geometry.size.height)
                }
            }
        }
    }
}

// MARK: - RoutePlanView

struct RoutePlanView: View {

    // MARK: Properties

    let routePlannderStore: RoutePlannerStore

    // MARK: Content

    var body: some View {
        VStack {
            VStack(alignment: .destinationIconCenterAlignment) {
                ForEach(self.routePlannderStore.state.destinations, id: \.self) { destination in
                    RoutePlannerRow(
                        destination: destination,
                        onSwap: self.swapActionIfCanSwap(for: destination),
                        onDelete: self.deleteActionIfCanDelete(for: destination)
                    )
                    .animation(.bouncy, value: destination)
                }
                AddMoreRoute {
                    self.routePlannderStore.addNewRoute()
                }
            }
            StartNavigationButton {
                self.routePlannderStore.startNavigation()
            }
            .padding(.horizontal)
        }
    }

    // MARK: Functions

    func swapActionIfCanSwap(for destination: RouteWaypoint) -> (() -> Void)? {
        if self.routePlannderStore.state.destinations.first == destination,
           self.routePlannderStore.state.canSwap {
            {
                Task {
                    await self.routePlannderStore.swap()
                }
            }
        } else {
            nil
        }
    }

    func deleteActionIfCanDelete(for destination: RouteWaypoint) -> (() -> Void)? {
        if self.routePlannderStore.state.canRemove {
            {
                Task {
                    await self.routePlannderStore.remove(destination)
                }
            }
        } else {
            nil
        }
    }
}

// MARK: - RoutePlannerRow

struct RoutePlannerRow: View {

    // MARK: Properties

    let destination: RouteWaypoint
    let onSwap: (() -> Void)?
    let onDelete: (() -> Void)?

    // MARK: Content

    var body: some View {
        VStack(alignment: .destinationIconCenterAlignment, spacing: 6) {
            HStack {
                DestinationImage(destinationType: self.destination.type)
                    .alignmentGuide(.destinationIconCenterAlignment) { $0[HorizontalAlignment.center] }
                Text(self.destination.title)
                    .hudhudFontStyle(.labelMedium)
                    .foregroundStyle(Color.Colors.General._01Black)
                Spacer()
                if let onDelete {
                    Button {
                        Logger.navigationPath.notice("drag and drop")
                    } label: {
                        Image(systemSymbol: .line3Horizontal)
                            .tint(Color.gray)
                    }
                    Divider()
                    Button(action: onDelete) {
                        Image(systemSymbol: .xmark)
                            .tint(Color.gray)
                    }
                }
            }
            .padding(.trailing)
            HStack {
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
                .alignmentGuide(.destinationIconCenterAlignment) { $0[HorizontalAlignment.center] }
                Rectangle()
                    .fill(Color.black.opacity(0.1))
                    .frame(width: .infinity, height: 1)
                    .overlay(alignment: .trailing) {
                        if let onSwap {
                            Button(action: onSwap) {
                                Image(.swapIcon)
                                    .padding(6)
                                    .background(Circle().fill(Color(red: 242 / 255, green: 242 / 255, blue: 242 / 255)))
                                    .padding(.trailing)
                            }
                        }
                    }
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

// MARK: - AddMoreRoute

struct AddMoreRoute: View {

    // MARK: Properties

    let onClick: () -> Void

    // MARK: Content

    var body: some View {
        Button(action: self.onClick) {
            VStack(alignment: .destinationIconCenterAlignment) {
                Label {
                    HStack {
                        Text("Add Stop")
                            .hudhudFontStyle(.labelMedium)
                            .foregroundStyle(Color(.secondaryLabel))
                        Spacer()
                    }
                } icon: {
                    Image(.addStopIcon)
                        .alignmentGuide(.destinationIconCenterAlignment) { $0[HorizontalAlignment.center] }
                }
                Label {
                    Rectangle()
                        .fill(Color.black.opacity(0.1))
                        .frame(width: .infinity, height: 1)
                } icon: {
                    Circle()
                        .fill(.white)
                        .frame(width: 4)
                        .alignmentGuide(.destinationIconCenterAlignment) { $0[HorizontalAlignment.center] }
                }
            }
            .padding([.leading, .trailing])
        }
    }
}

// MARK: - StartNavigationButton

struct StartNavigationButton: View {

    // MARK: Properties

    let onClick: () -> Void

    // MARK: Content

    var body: some View {
        Button(action: self.onClick) {
            HStack {
                Spacer()
                Label("Start Trip", image: .directionsIcon)
                    .hudhudFontStyle(.labelMedium)
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.vertical)
            .background(
                RoundedRectangle(cornerRadius: 50)
                    .fill(Color.Colors.Road._02DarkGreen)
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

    static let destinationIconCenterAlignment = HorizontalAlignment(LocationIconCenterAlignment.self)
}

#Preview {
    RoutePlannerView(routePlannerStore: .storeSetUpForPreviewing)
}
