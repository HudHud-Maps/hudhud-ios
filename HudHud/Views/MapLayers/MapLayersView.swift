//
//  MapLayersView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 18/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import OSLog
import SwiftUI

struct MapLayersView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var mapStore: MapStore
    @State var currentlySelected: String?
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
                        var groupedLayers = Dictionary(grouping: mapLayers, by: { $0.type })
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
                        Text("")
                            .backport.contentUnavailable(label: "No Map Layers Available", SFSymbol: .globeCentralSouthAsiaFill)
                    }
                }
            }
        }
    }

    // MARK: - Internal

    func mapLayerView(mapLayers: [HudHudMapLayer]) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(mapLayers.first?.displayType ?? "")
                .hudhudFont(.footnote)
                .foregroundStyle(Color.Colors.General._02Grey)
                .padding(.leading, 10)
            if mapLayers.count > 2 {
                ScrollView(.horizontal) {
                    self.layersView(mapLayers: mapLayers)
                }.scrollIndicators(.hidden)
            } else {
                self.layersView(mapLayers: mapLayers)
            }
        }
    }

    func layersView(mapLayers: [HudHudMapLayer]) -> some View {
        HStack {
            ForEach(mapLayers, id: \.self) { layer in
                HStack {
                    if mapLayers.last?.type != layer.type {
                        Divider()
                    }
                    VStack(alignment: .center, spacing: 10) {
                        Button {
                            self.currentlySelected = layer.name
                            // this if just for testing I will remove it before the merge
                            if layer.name == "Satellite" {
                                self.mapStore.mapStyleURLString = "https://api.maptiler.com/tiles/v3-openmaptiles/tiles.json?key=NuXvtnILACeadkgsn5xZ"
                            } else {
                                self.mapStore.mapStyleURLString = layer.styleUrl.absoluteString
                                Logger().info("\(layer.name) selected as map Style")
                            }
                        } label: {
                            AsyncImage(url: layer.thumbnailUrl) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: (UIScreen.main.bounds.width / 2) - 20, height: 119)
                            .background(Color.Colors.General._03LightGrey)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(self.currentlySelected == layer.name ? Color.Colors.General._07BlueMain : .clear, lineWidth: 2)
                            )
                        }
                        Text(layer.name)
                            .hudhudFont(.footnote)
                            .foregroundStyle(self.currentlySelected == layer.name ? Color.Colors.General._07BlueMain : Color.Colors.General._02Grey)
                    }
                }
            }
        }
    }
}

#Preview {
    let hudhudMapLayerStore = HudHudMapLayerStore()
    let searchViewStore: SearchViewStore = .storeSetUpForPreviewing
    return MapLayersView(mapStore: searchViewStore.mapStore, hudhudMapLayerStore: hudhudMapLayerStore)
        .padding(.horizontal, 20)
}
