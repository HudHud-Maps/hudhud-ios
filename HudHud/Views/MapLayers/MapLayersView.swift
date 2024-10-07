//
//  MapLayersView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 18/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import NukeUI
import OSLog
import SwiftUI

struct MapLayersView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var mapStore: MapStore
    var sheetStore: SheetStore
    var hudhudMapLayerStore: HudHudMapLayerStore

    var body: some View {
        VStack(alignment: .center, spacing: 15) {
            HStack(alignment: .center) {
                if self.hudhudMapLayerStore.hudhudMapLayers != nil {
                    Spacer()
                    Text("Layers")
                        .hudhudFont(.headline)
                        .foregroundStyle(Color.Colors.General._01Black)
                } else {
                    Text("")
                        .padding(.top, 30)
                }
                Spacer()
                Button {
                    self.sheetStore.popSheet()
                    self.dismiss()
                } label: {
                    Image(systemSymbol: .xmark)
                        .foregroundColor(Color.Colors.General._02Grey)
                }
            }
            .padding(.horizontal, 15)
            .padding(.top, 5)
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    if let mapLayers = self.hudhudMapLayerStore.hudhudMapLayers {
                        let groupedLayers = Dictionary(grouping: mapLayers, by: { $0.type.rawValue })
                        let sortedTypes = groupedLayers.keys.sorted {
                            $0 == "map_type" ? true : $1 == "map_details"
                        }
                        VStack(alignment: .center, spacing: 15) {
                            ForEach(sortedTypes, id: \.self) { key in
                                if let layers = groupedLayers[key] {
                                    self.mapLayerView(mapLayers: layers)
                                }
                            }
                        }
                    } else {
                        ContentUnavailableView {
                            Label("No Map Layers Available", systemSymbol: .globeCentralSouthAsiaFill)
                        } description: {
                            Text("No Content To be Shown Here.")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Internal

    func mapLayerView(mapLayers: [HudHudMapLayer]) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(mapLayers.first?.type.description ?? "")
                .hudhudFont(.footnote)
                .foregroundStyle(Color.Colors.General._02Grey)
                .padding(.leading, 10)
            if mapLayers.count > 2 {
                ScrollView(.horizontal) {
                    self.layersView(mapLayers: mapLayers)
                }.scrollIndicators(.hidden)
                    .padding(.horizontal)
            } else {
                self.layersView(mapLayers: mapLayers)
                    .padding(.horizontal)
            }
        }
    }

    func layersView(mapLayers: [HudHudMapLayer]) -> some View {
        HStack {
            ForEach(mapLayers, id: \.self) { layer in
                HStack {
                    if mapLayers.last?.type.description != layer.type.description {
                        Divider()
                    }
                    VStack(alignment: .center, spacing: 10) {
                        Button {
                            self.mapStore.shouldShowCustomSymbols = false
                            self.mapStore.mapStyleLayer = layer
                            Logger().info("\(layer.name) selected as map Style | url:\(layer.styleUrl)")
                        } label: {
                            LazyImage(url: layer.thumbnailUrl) { state in
                                if let image = state.image {
                                    image.resizable().aspectRatio(contentMode: .fit)
                                } else if state.error != nil {
                                    Image("DefaultLayerImage")
                                        .resizable()
                                        .scaledToFit()
                                        .grayscale(1.0)
                                        .saturation(0.5)
                                } else {
                                    Image("DefaultLayerImage")
                                        .resizable()
                                        .scaledToFit()
                                        .grayscale(1.0)
                                        .saturation(0.5)
                                }
                            }
                            .background(Color.Colors.General._03LightGrey)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(self.mapStore.mapStyleLayer == layer ? Color.Colors.General._07BlueMain : .clear, lineWidth: 2)
                            )
                        }
                        Text(layer.name)
                            .hudhudFont(.footnote)
                            .foregroundStyle(Color.Colors.General._02Grey)
                            .foregroundStyle(self.mapStore.mapStyleLayer == layer ? Color.Colors.General._07BlueMain : Color.Colors.General._02Grey)
                    }
                }
            }
        }
    }
}

#Preview {
    let hudhudMapLayerStore = HudHudMapLayerStore()
    return MapLayersView(
        mapStore: .storeSetUpForPreviewing,
        sheetStore: .storeSetUpForPreviewing,
        hudhudMapLayerStore: hudhudMapLayerStore
    )
    .padding(.horizontal, 20)
}
