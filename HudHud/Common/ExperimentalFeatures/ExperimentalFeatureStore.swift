//
//  ExperimentalFeatureStore.swift
//  HudHud
//
//  Created by Ali Hilal on 07/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import UIKit

// MARK: - ExperimentalFeatureStore

@Observable
final class ExperimentalFeatureStore {

    // MARK: Static Properties

    static let shared = ExperimentalFeatureStore()

    // MARK: Properties

    var currentEnvironment: UIApplication.Environment = UIApplication.environment

    private var features: [String: Bool] = [:]

    // MARK: Lifecycle

    private init() {
        self.loadFeatures()
    }

    // MARK: Functions

    func isEnabled(_ feature: ExperimentalFeature) -> Bool {
        guard feature.isAllowed(for: self.currentEnvironment) else { return false }

        return self.features[feature.featureDescription.description] ?? false
    }

    func setEnabled(_ enabled: Bool, for feature: ExperimentalFeature) {
        self.features[feature.featureDescription.description] = enabled
        self.saveFeatures()
    }
}

// MARK: - Private

private extension ExperimentalFeatureStore {

    func saveFeatures() {
        UserDefaults.standard.set(self.features, forKey: "experimental_features")
    }

    func loadFeatures() {
        self.features = UserDefaults.standard.dictionary(forKey: "experimental_features") as? [String: Bool] ?? [:]
    }
}
