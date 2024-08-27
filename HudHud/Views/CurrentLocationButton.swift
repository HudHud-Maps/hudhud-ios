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
import SwiftUI

struct CurrentLocationButton: View {

    // MARK: Properties

    @ObservedObject var mapStore: MapStore

    // MARK: Content

    var body: some View {
        Button {
            Task {
                await self.mapStore.switchToNextTrackingAction()
            }
        } label: {
            self.trackingUI
        }
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
        .fixedSize()
    }

    @ViewBuilder
    private var trackingUI: some View {
        switch self.mapStore.trackingState {
        case .none:
            Image(systemSymbol: .location)
                .font(.title2)
                .padding(10)
                .foregroundColor(.gray)
        case .locateOnce:
            Image(systemSymbol: .locationFill)
                .font(.title2)
                .padding(10)
                .foregroundColor(.gray)
        case .keepTracking:
            Image(systemSymbol: .locationNorthFill)
                .font(.title2)
                .padding(10)
                .foregroundColor(.gray)
        }
    }

}

@available(iOS 17, *)
#Preview(traits: .sizeThatFitsLayout) {
    @State var mapStore: MapStore = .storeSetUpForPreviewing
    return CurrentLocationButton(mapStore: mapStore)
        .padding()
}
