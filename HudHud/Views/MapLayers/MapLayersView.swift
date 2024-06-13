//
//  MapLayersView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 18/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import SwiftUI

struct MapLayersView: View {
    @State var currentlySelected: String?
    var mapLayerStore: HudHudMapLayerStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                if let mapLayers = self.mapLayerStore.mapLayers {
                    ForEach(mapLayers, id: \.name) { layer in
                        VStack {
                            Button {
                                self.currentlySelected = layer.name
                            } label: {
                                AsyncImage(url: URL(string: layer.thumbnail_url)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 110, height: 110)
                                .background(.secondary)
                                .cornerRadius(4.0)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(self.currentlySelected == layer.name ? .green : .clear, lineWidth: 2)
                                )
                            }
                            Text(layer.name)
                                .foregroundStyle(self.currentlySelected == layer.name ? .green : .secondary)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    var mapLayerStore: HudHudMapLayerStore = .init()
    return MapLayersView(mapLayerStore: mapLayerStore)
        .padding(.horizontal, 20)
}
