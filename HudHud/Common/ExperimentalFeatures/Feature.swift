//
//  Feature.swift
//  HudHud
//
//  Created by Ali Hilal on 09/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import UIKit

@propertyWrapper
struct Feature {

    // MARK: Properties

    private let feature: ExperimentalFeature
    private let defaultValue: Bool

    // MARK: Computed Properties

    var wrappedValue: Bool {
        get {
            let store = ExperimentalFeatureStore.shared
            return store.isEnabled(self.feature)
        }
        set {
            ExperimentalFeatureStore.shared.setEnabled(newValue, for: self.feature)
        }
    }

    // MARK: Lifecycle

    init(_ feature: ExperimentalFeature, defaultValue: Bool = false) {
        self.feature = feature
        self.defaultValue = defaultValue
    }
}
