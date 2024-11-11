//
//  Feature.swift
//  HudHud
//
//  Created by Ali Hilal on 09/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

@propertyWrapper
struct Feature<T> {

    // MARK: Properties

    private let feature: ExperimentalFeature
    private let defaultValue: T
    private let allowedEnvironments: Set<AppEnvironment>

    // MARK: Computed Properties

    var wrappedValue: T {
        get {
            let store = ExperimentalFeatureStore.shared
            guard self.allowedEnvironments.contains(store.currentEnvironment) else {
                return self.defaultValue
            }
            return store.getValue(for: self.feature) ?? self.defaultValue
        }
        set {
            ExperimentalFeatureStore.shared.setValue(newValue, for: self.feature)
        }
    }

    // MARK: Lifecycle

    init(_ feature: ExperimentalFeature,
         defaultValue: T,
         allowedIn environments: [AppEnvironment] = [.development, .staging]) {
        self.feature = feature
        self.defaultValue = defaultValue
        self.allowedEnvironments = Set(environments)
    }

    init(_ feature: ExperimentalFeature,
         allowedIn environments: [AppEnvironment] = [.development, .staging]) where T == Bool {
        self.init(feature, defaultValue: false, allowedIn: environments)
    }
}
