//
//  RoutePlannerMapOverlayView.swift
//  HudHud
//
//  Created by Naif Alrashed on 12/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

// MARK: - RoutePlannerMapOverlayView

struct RoutePlannerMapOverlayView: View {

    // MARK: Properties

    let routePlannerStore: RoutePlannerStore
    let sheetStore: SheetStore

    // MARK: Computed Properties

    private var routeCardsOffset: CGFloat {
        if self.routePlannerStore.isLoading {
            0
        } else {
            -(self.sheetStore.sheetHeight + 8)
        }
    }

    // MARK: Content

    var body: some View {
        VStack {
            HStack {
                Button {
                    self.routePlannerStore.cancel()
                } label: {
                    Image(.arrowBack)
                        .padding()
                        .background {
                            Circle()
                                .fill(.white)
                        }
                        .frame(minWidth: 44, minHeight: 44)
                }
                .padding(.leading)
                Spacer()
            }
            Spacer()
            RouteCardsView(
                routes: (self.routePlannerStore.routePlan?.routes ?? []).map {
                    RouteViewData(
                        id: $0.id,
                        distance: distanceFormatter.string(
                            from: Measurement.meters($0.distance)
                                .converted(to: .kilometers)
                        ),
                        duration: durationFormatter.string(
                            from: Date(),
                            to: Date(timeIntervalSinceNow: $0.duration)
                        ) ?? "",
                        summary: "A close destination"
                    )
                },
                selectedRoute: Binding(
                    get: { self.routePlannerStore.routePlan?.selectedRoute.id },
                    set: { routeID in
                        if let routeID {
                            self.routePlannerStore.selectRoute(withID: routeID)
                        }
                    }
                )
            )
            .offset(y: self.routeCardsOffset)
            .animation(.easeInOut(duration: 0.2), value: self.routeCardsOffset)
        }
    }
}

#Preview {
    RoutePlannerMapOverlayView(routePlannerStore: .storeSetUpForPreviewing, sheetStore: .storeSetUpForPreviewing)
}

private let distanceFormatter: MeasurementFormatter = {
    let distanceFormatter = MeasurementFormatter()
    distanceFormatter.unitOptions = .providedUnit
    distanceFormatter.unitStyle = .medium
    return distanceFormatter
}()

private let durationFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute]
    formatter.unitsStyle = .brief
    formatter.zeroFormattingBehavior = .dropAll
    return formatter
}()
