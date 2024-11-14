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

    // MARK: Properties

    var mapStore: MapStore
    var sheetStore: SheetStore
    @StateObject var hudhudMapLayerStore: HudHudMapLayerStore

    // MARK: Content

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                if let mapLayers = self.hudhudMapLayerStore.hudhudMapLayers {
                    self.mapLayerView(mapLayers: mapLayers)
                    HStack {
                        Spacer()
                        ForEach(self.hudhudMapLayerStore.mapStyleTypes, id: \.self) { type in
                            self.mapLayerButtons(for: type, label: type.title)
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                } else {
                    ContentUnavailableView {
                        Label("No Map Layers Available", systemSymbol: .globeCentralSouthAsiaFill)
                    } description: {
                        Text("No Content To be Shown Here.")
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Map Layers")
                        .hudhudFontStyle(.labelLarge)
                        .padding(.top)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        self.sheetStore.popSheet()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.Colors.General._03LightGrey)
                                .frame(width: 30, height: 30)
                            Image(systemSymbol: .xmark)
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundStyle(Color.Colors.General._01Black)
                        }
                        .padding(4)
                        .contentShape(Circle())
                    }
                    .padding(.top)
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel(Text("Close", comment: "Accessibility label instead of x"))
                }
            }
        }
    }

    // MARK: - Internal

    func mapLayerView(mapLayers: [HudHudMapLayer]) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            if mapLayers.count > 3 {
                ScrollView(.horizontal) {
                    self.layersView(mapLayers: mapLayers)
                }.scrollIndicators(.hidden)
                    .padding(.horizontal)
            } else {
                self.layersView(mapLayers: mapLayers)
                    .padding(.horizontal)
            }
        }
        .padding(.top, 20)
    }

    func layersView(mapLayers: [HudHudMapLayer]) -> some View {
        HStack {
            ForEach(mapLayers, id: \.self) { layer in
                HStack {
                    VStack(alignment: .center, spacing: 10) {
                        Button {
                            self.mapStore.shouldShowCustomSymbols = false
                            self.mapStore.mapStyleLayer = layer
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
                                    .stroke(self.mapStore.mapStyleLayer == layer ? Color.Colors.General._06DarkGreen : .clear, lineWidth: 2)
                            )
                        }
                        Text(layer.name)
                            .hudhudFont(.footnote)
                            .foregroundStyle(Color.Colors.General._01Black)
                    }
                }
            }
        }
    }

    func mapLayerButtons(for type: HudHudMapLayerStore.mapStyleType, label: String) -> some View {
        VStack(alignment: .center, spacing: 8) {
            Button {
                // It should connect to the backend to trigger the action
                // Toggle the buttons selected state
                self.hudhudMapLayerStore.buttonStyleAction(for: type)
                if let selectedLayer = hudhudMapLayerStore.layer(for: type) {
                    self.mapStore.mapStyleLayer = selectedLayer
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(self.hudhudMapLayerStore.selectedStyle.contains(type) ? Color.Colors.General._11GreenLight : Color.Colors.General._03LightGrey)
                        .frame(width: 48, height: 48)
                    self.getCustomImage(for: type)
                        .renderingMode(.template)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(self.hudhudMapLayerStore.selectedStyle.contains(type) ? Color.Colors.General._06DarkGreen : Color.Colors.General._02Grey)
                }
                .padding(4)
                .contentShape(Circle())
            }
            Text(label)
                .hudhudFontStyle(.labelSmall)
                .foregroundColor(Color.Colors.General._01Black)
        }
    }

    // MARK: Functions

    func getCustomImage(for type: HudHudMapLayerStore.mapStyleType) -> Image {
        switch type {
        case .traffic:
            return Image(.traffic)
        case .saved:
            return Image(.saveIconFill)
        case .streetView:
            return Image(.signpost)
        case .road:
            return Image(.road)
        }
    }
}

#Preview {
    let hudhudMapLayerStore = HudHudMapLayerStore()
    MapLayersView(
        mapStore: .storeSetUpForPreviewing,
        sheetStore: .storeSetUpForPreviewing,
        hudhudMapLayerStore: hudhudMapLayerStore
    )
    .padding(.horizontal, 20)
}
