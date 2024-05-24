//
//  MainLayersView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 19/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct MainLayersView: View {
    var mapLayerData: [MapLayersData]

    var body: some View {
        VStack(alignment: .center, spacing: 15) {
            ForEach(self.mapLayerData) { layer in
                MapLayersView(mapLayerData: layer)
                if self.mapLayerData.last?.id.uuidString != layer.id.uuidString {
                    Divider()
                }
            }
        }
    }
}

#Preview {
    return VStack(alignment: .center, spacing: 30) {
        HStack(alignment: .center) {
            Spacer()
            Text("Layers")
                .foregroundStyle(.primary)
            Spacer()
            Button {
                print("X button pressed")
            } label: {
                Image(systemSymbol: .xmark)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 30)
        MainLayersView(mapLayerData: MapLayersData.getLayers())
    }
}
