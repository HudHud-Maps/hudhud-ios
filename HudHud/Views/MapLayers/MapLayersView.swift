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
    @Environment(\.dismiss) private var dismiss
    @State var currentlySelected: String?
    var hudhudMapLayerStore: HudHudMapLayerStore

    var body: some View {
        VStack(alignment: .center, spacing: 25) {
            HStack(alignment: .center) {
                if self.hudhudMapLayerStore.hudhudMapLayers != nil {
                    Spacer()
                    Text("Layers")
                        .foregroundStyle(.primary)
                } else {
                    Text("")
                        .padding(.top, 30)
                }
                Spacer()
                Button {
                    self.dismiss()
                } label: {
                    Image(systemSymbol: .xmark)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 30)
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    if let mapLayers = self.hudhudMapLayerStore.hudhudMapLayers {
                        ForEach(mapLayers, id: \.name) { layer in
                            VStack {
                                Button {
                                    self.currentlySelected = layer.name
                                } label: {
                                    AsyncImage(url: layer.thumbnailUrl) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(width: 110, height: 110)
                                    //									.cornerRadius(4.0)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(self.currentlySelected == layer.name ? .blue : .clear, lineWidth: 2)
                                    )
                                }
                                Text(layer.name)
                                    .foregroundStyle(self.currentlySelected == layer.name ? .blue : .secondary)
                            }
                        }
                    } else {
                        Text("")
                            .backport.contentUnavailable(label: "No Map Layers Available", SFSymbol: .globeCentralSouthAsiaFill)
                    }
                }
            }
        }
    }
}

#Preview {
    let hudhudMapLayerStore = HudHudMapLayerStore()
    return MapLayersView(hudhudMapLayerStore: hudhudMapLayerStore)
        .padding(.horizontal, 20)
}
