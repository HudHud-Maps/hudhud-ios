//
//  View+Experimental.swift
//  HudHud
//
//  Created by Ali Hilal on 07/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

extension View {
    func experimental(_ feature: ExperimentalFeature, allowedIn environments: AppEnvironment...) -> some View {
        modifier(ExperimentalViewModifier(feature: feature, environments: environments))
    }
}

extension View {
    func featureEnabled(_ feature: ExperimentalFeature) -> some View {
        self.experimental(feature, allowedIn: .development, .staging)
    }

    func devFeature(_ feature: ExperimentalFeature) -> some View {
        self.experimental(feature, allowedIn: .development)
    }
}

// MARK: - ExperimentalViewModifier

private struct ExperimentalViewModifier: ViewModifier {
    @State private var store = ExperimentalFeatureStore.shared
    let feature: ExperimentalFeature
    let environments: [AppEnvironment]

    func body(content: Content) -> some View {
        if self.environments.contains(self.store.currentEnvironment),
           self.store.getValue(for: self.feature) ?? false {
            content
        }
    }
}
