//
//  MapStyles.swift
//  HudHud
//
//  Created by Fatima Aljaber on 25/03/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import MapboxCoreNavigation
import MapboxDirections
import MapboxNavigation
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import SwiftUI

// MARK: - CustomDayStyle

class CustomDayStyle: DayStyle {

	// MARK: - Lifecycle

	required init() {
		super.init()
		//	mapStyleURL = URL(string: "mapbox://styles/mapbox/satellite-streets-v9")!
		styleType = .day
	}

	// MARK: - Internal

	override func apply() {
		super.apply()
		InstructionsBannerView.appearance().backgroundColor = .systemGreen
		InstructionsBannerContentView.appearance().backgroundColor = .systemGreen
		DistanceLabel.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).unitTextColor = .white
		DistanceLabel.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).valueTextColor = .white
		DistanceLabel.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).normalTextColor = .white
		DistanceLabel.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).textColor = .white
		PrimaryLabel.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).normalTextColor = .white
		SecondaryLabel.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).normalTextColor = .white
	}
}

// MARK: - CustomNightStyle

class CustomNightStyle: NightStyle {

	// MARK: - Lifecycle

	required init() {
		super.init()
		styleType = .night
	}

	// MARK: - Internal

	override func apply() {
		super.apply()
		InstructionsBannerView.appearance().backgroundColor = .systemGreen
		InstructionsBannerContentView.appearance().backgroundColor = .systemGreen
		DistanceLabel.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).unitTextColor = .white
		DistanceLabel.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).valueTextColor = .white
		DistanceLabel.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).normalTextColor = .white
		DistanceLabel.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).textColor = .white
		PrimaryLabel.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).normalTextColor = .white
		SecondaryLabel.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).normalTextColor = .white
	}
}
