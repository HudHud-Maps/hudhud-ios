//
//  MapLayersData.swift
//  HudHud
//
//  Created by Fatima Aljaber on 18/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - MapLayersData

struct MapLayersData: Identifiable {
	let id = UUID()
	let layerTitle: String
	var layers: [Layer]

	// MARK: - Lifecycle

	init(layerTitle: String, layers: [Layer]) {
		self.layerTitle = layerTitle
		self.layers = layers
	}

	// MARK: - Internal

	// MARK: - Test Data

	static func getLayers() -> [MapLayersData] {
		let layer = Layer(imageTitle: "Map 1", imageUrl: "https://i.ibb.co/NSRMfxC/1.jpg", isSelected: false)
		let layer1 = Layer(imageTitle: "Map 2", imageUrl: "https://i.ibb.co/NSRMfxC/1.jpg", isSelected: true)
		let layer2 = Layer(imageTitle: "Map 3", imageUrl: "https://i.ibb.co/NSRMfxC/1.jpg", isSelected: true)
		let layerOne = MapLayersData(layerTitle: "Map Type", layers: [layer, layer1, layer2])
		let layerTwo = MapLayersData(layerTitle: "Map Details", layers: [layer, layer1, layer2])
		return [layerOne, layerTwo]
	}
}

// MARK: - Layer

struct Layer: Identifiable {
	let id = UUID()
	let imageTitle: String
	let imageUrl: String
	var isSelected: Bool

	// MARK: - Lifecycle

	init(imageTitle: String, imageUrl: String, isSelected: Bool) {
		self.imageTitle = imageTitle
		self.imageUrl = imageUrl
		self.isSelected = isSelected
	}
}
