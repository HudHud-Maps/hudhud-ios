//
//  ExperimentalFeature.swift
//  HudHud
//
//  Created by Ali Hilal on 07/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import UIKit

// MARK: - FeatureDescription

struct FeatureDescription: Codable {
    let description: String
    let environments: [UIApplication.Environment]
}

// MARK: - ExperimentalFeature

enum ExperimentalFeature: CaseIterable {
    case safetyCamsAndAlerts
    case enableNewRoutePlanner
}

extension ExperimentalFeature {

    // Provide the feature description for each case
    var featureDescription: FeatureDescription {
        switch self {
        case .safetyCamsAndAlerts:
            return FeatureDescription(description: "Safety Cams & Alerts",
                                      environments: .upToTestFlight)
        case .enableNewRoutePlanner:
            return FeatureDescription(description: "Enable New Route Planner",
                                      environments: .upToTestFlight)
        }
    }

    // MARK: Functions

    func isAllowed(for environment: UIApplication.Environment) -> Bool {
        return self.featureDescription.environments.contains(environment)
    }
}

// MARK: - Identifiable

extension ExperimentalFeature: Identifiable {
    var id: String {
        return String(describing: self)
    }
}
