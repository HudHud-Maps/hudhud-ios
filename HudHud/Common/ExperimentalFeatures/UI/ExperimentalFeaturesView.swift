//
//  ExperimentalFeaturesView.swift
//  HudHud
//
//  Created by Ali Hilal on 09/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI
import UIKit

// MARK: - ExperimentalFeaturesView

struct ExperimentalFeaturesView: View {

    // MARK: Properties

    @Environment(\.dismiss) private var dismiss
    @State private var store = ExperimentalFeatureStore.shared

    // MARK: Content

    var body: some View {
        NavigationStack {
            List {
                Section("Features") {
                    ForEach(ExperimentalFeature.allCases) { feature in
                        FeatureToggleRow(feature: feature)
                    }
                }

                Section("Environment") {
                    Picker("Current Environment", selection: self.$store.currentEnvironment) {
                        ForEach(UIApplication.Environment.allCases, id: \.self) { env in
                            Text(env.rawValue.capitalized)
                                .tag(env)
                        }
                    }
                }
            }
            .navigationTitle("Experimental Features")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        self.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - FeatureToggleRow

struct FeatureToggleRow: View {

    // MARK: Properties

    let feature: ExperimentalFeature

    @State private var store = ExperimentalFeatureStore.shared

    // MARK: Content

    var body: some View {
        Toggle(isOn: Binding(get: { self.store.isEnabled(self.feature) },
                             set: { self.store.setEnabled($0, for: self.feature) }), label: {
                Text(self.feature.featureDescription.description)
            })
            .toggleStyle(EnableableToggleStyle())
            .enabled(self.feature.isAllowed(for: self.store.currentEnvironment))
    }
}

// MARK: - Private

private extension View {

    nonisolated func enabled(_ enabled: Bool) -> some View {
        self.disabled(enabled == false)
    }
}
