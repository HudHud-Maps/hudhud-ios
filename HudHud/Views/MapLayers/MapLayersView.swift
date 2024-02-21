//
//  MapLayersView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 18/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI
struct MapLayersView: View {
	var mapLayerData: MapLayersData
	@State var currentlySelected: String?
    var body: some View {
		VStack(alignment: .leading, spacing: 10) {
			Text(mapLayerData.layerTitle)				.foregroundStyle(.secondary)
			HStack {
				ForEach(self.mapLayerData.layers) { layer in
					VStack {
						Button {
							currentlySelected = layer.id.uuidString
						} label: {
						AsyncImage(url: URL(string: layer.imageUrl)) { image in
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
									.stroke(self.currentlySelected == layer.id.uuidString ? .green : .clear, lineWidth: 2)
							   )
						}
						Text(layer.imageTitle)
							.foregroundStyle(self.currentlySelected == layer.id.uuidString ? .green : .secondary)
					}
				}
			}
		}
    }
}

#Preview {
	var layer = Layer(imageTitle: "Map 1", imageUrl: "https://i.ibb.co/NSRMfxC/1.jpg", isSelected: false)
	var layer1 = Layer(imageTitle: "Map 2", imageUrl: "https://i.ibb.co/NSRMfxC/1.jpg", isSelected: true)
	var layer2 = Layer(imageTitle: "Map 3", imageUrl: "https://i.ibb.co/NSRMfxC/1.jpg", isSelected: true)
	var mapLayerData = MapLayersData(layerTitle: "Map Type", layers: [layer, layer1, layer2])
	return MapLayersView(mapLayerData: mapLayerData)
		.padding(.horizontal, 20)
}
