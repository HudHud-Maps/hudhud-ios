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

    required init(mapStyleURL: URL) {
        super.init(mapStyleURL: mapStyleURL)
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
        ManeuverView.appearance().backgroundColor = .clear
        ManeuverView.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).primaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        ManeuverView.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).secondaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.3)
    }
}

// MARK: - CustomNightStyle

class CustomNightStyle: NightStyle {

    // MARK: - Lifecycle

    required init(mapStyleURL: URL) {
        super.init(mapStyleURL: mapStyleURL)
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
        ManeuverView.appearance().backgroundColor = .clear
        ManeuverView.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).primaryColor = #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1)
        ManeuverView.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).secondaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.3)
    }
}
