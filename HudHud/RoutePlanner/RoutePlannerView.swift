//
//  RoutePlannerView.swift
//  HudHud
//
//  Created by Naif Alrashed on 30/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

// MARK: - RoutePlannerView

struct RoutePlannerView: View {

    // MARK: Properties

    @State var routePlannerStore: RoutePlannerStore

    // MARK: Content

    var body: some View {
        VStack {
            RoutePlannerRow()
            RoutePlannerRow()
        }
    }
}

// MARK: - RoutePlannerRow

struct RoutePlannerRow: View {
    var body: some View {
        VStack(alignment: .locationIconCenterAlignment, spacing: 6) {
            Label {
                HStack {
                    Text("Current Location")
                        .hudhudFontStyle(.labelMedium)
                        .foregroundStyle(Color.Colors.General._01Black)
                    Spacer()
                }
            } icon: {
                Image(systemSymbol: .locationFill)
                    .alignmentGuide(.locationIconCenterAlignment) { $0[HorizontalAlignment.center] }
            }
            Label {
                Rectangle()
                    .fill(Color.black.opacity(0.1))
                    .frame(width: .infinity, height: 1)
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
            .padding(.leading)
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
