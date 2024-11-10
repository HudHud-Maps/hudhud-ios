//
//  ExperimentalFeatureStore.swift
//  HudHud
//
//  Created by Ali Hilal on 07/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

// MARK: - ExperimentalFeatureStore

@Observable
final class ExperimentalFeatureStore {

    // MARK: Static Properties

    static let shared = ExperimentalFeatureStore()

    // MARK: Properties

    var currentEnvironment: AppEnvironment = .inferred

    private var features: [String: Any] = [:]

    // MARK: Lifecycle

    private init() {
        loadFeatures()
    }

    // MARK: Functions

    func getValue<T>(for feature: ExperimentalFeature) -> T? {
        self.features[feature.rawValue] as? T
    }

    func setValue(_ value: some Any, for feature: ExperimentalFeature) {
        self.features[feature.rawValue] = value
        saveFeatures()
    }

    func isEnabled(_ feature: ExperimentalFeature) -> Bool {
        self.getValue(for: feature) ?? false
    }

    func setEnabled(_ enabled: Bool, for feature: ExperimentalFeature) {
        self.setValue(enabled, for: feature)
    }
}

private extension ExperimentalFeatureStore {
    func saveFeatures() {
        UserDefaults.standard.set(self.features, forKey: "experimental_features")
    }

    func loadFeatures() {
        self.features = UserDefaults.standard.dictionary(forKey: "experimental_features") ?? [:]
    }
}
