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
		VStack(alignment: .center, spacing: 30) {
				HStack(alignment: .center) {
					Spacer()
					Text("Layers").bold()
					Spacer()
					Button {
						print("X button pressed")
					} label: {
						Image(systemSymbol: .xmark)
							.foregroundColor(.gray)
					}
				}
				.padding(.horizontal, 30)
			VStack(alignment: .center, spacing: 15) {
				ForEach(self.mapLayerData) { layer in
					MapLayersView(mapLayerData: layer)
					if mapLayerData.last?.id.uuidString != layer.id.uuidString {
						Divider()
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
	let layerOne = MapLayersData(layerTitle: "Map Type", layers: [layer, layer1, layer2])
	let layerTwo = MapLayersData(layerTitle: "Map Detials", layers: [layer, layer1, layer2])
	return MainLayersView(mapLayerData: [layerOne, layerTwo])
}
