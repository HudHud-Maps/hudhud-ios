//
//  CurrentLocationButton.swift
//  HudHud
//
//  Created by Patrick Kladek on 31.01.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import MapLibre
import MapLibreSwiftUI
import OSLog
import SFSafeSymbols
import SwiftLocation
import SwiftUI

struct CurrentLocationButton: View {

    @State private var locationRequestInProgress = false
    @ObservedObject var mapStore: MapStore

    @ViewBuilder
    private var trackingUI: some View {
        switch self.mapStore.trackingState {
        case .none:
            Image(systemSymbol: .location)
                .font(.title2)
                .padding(10)
                .foregroundColor(.gray)
        case .locateOnce:
            if self.locationRequestInProgress {
                ProgressView()
                    .font(.title2)
                    .padding(13)
                    .foregroundColor(.gray)
            } else {
                Image(systemSymbol: .locationFill)
                    .font(.title2)
                    .padding(10)
                    .foregroundColor(.gray)
            }
        case .keepTracking:
            Image(systemSymbol: .locationNorthFill)
                .font(.title2)
                .padding(10)
                .foregroundColor(.gray)
        }
    }

    var body: some View {
        Button {
            self.trackingAction(for: self.mapStore.trackingState)
        } label: {
            self.trackingUI
        }
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
        .fixedSize()
        .disabled(self.locationRequestInProgress)
    }

    // MARK: - Internal

    func trackingAction(for trackingState: MapStore.TrackingState) {
        switch trackingState {
        case .none:
            Task {
                defer { self.locationRequestInProgress = false }
                do {
                    self.locationRequestInProgress = true
                    try await Location.forSingleRequestUsage.requestPermission(.whenInUse)
                    let userLocation = try await Location.forSingleRequestUsage.requestLocation()

                    if let coordinates = userLocation.location?.coordinate {
                        withAnimation {
                            Logger.mapInteraction.log("current Location of the user ")
                            self.mapStore.currentLocation = coordinates
                        }
                    } else {
                        Logger.searchView.error("location error: got no coordinates")
                    }
                } catch {
                    Logger.searchView.error("location error: \(error)")
                }
            }
            self.mapStore.trackingState = .locateOnce
            Logger.mapInteraction.log("None action required")
        case .locateOnce:
            self.mapStore.trackingState = .keepTracking
            Logger.mapInteraction.log("locate me Once")
        case .keepTracking:
            self.mapStore.trackingState = .none
            Logger.mapInteraction.log("keep Tracking of user location")
        }
    }

}

@available(iOS 17, *)
#Preview(traits: .sizeThatFitsLayout) {
    @State var mapStore: MapStore = .storeSetUpForPreviewing
    return CurrentLocationButton(mapStore: mapStore)
        .padding()
}
