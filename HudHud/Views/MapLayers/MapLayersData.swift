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
