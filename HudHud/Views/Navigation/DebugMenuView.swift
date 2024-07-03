//
//  DebugMenuView.swift
//  HudHud
//
//  Created by Alaa . on 12/05/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

// MARK: - DebugMenuView

struct DebugMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var debugSettings: DebugStore
    @ObservedObject var touchManager = TouchManager.shared

    var body: some View {
        Form {
            Section(header: Text("Routing Configuration")) {
                TextField("Routing URL", text: self.$debugSettings.routingHost)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }

            Section(header: Text("Simulation")) {
                Toggle(isOn: self.$debugSettings.simulateRide) {
                    Text("Simulate Ride during Navigation")
                }
            }

            Section(header: Text("Touch Visualizer")) {
                Toggle(isOn: self.$touchManager.isTouchVisualizerEnabled ?? self.touchManager.defaultTouchVisualizerSetting) {
                    Text("Enable Touch Visualizer")
                }
            }
        }
        .navigationTitle("Debug Menu")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    self.dismiss()
                }
            }
        }
    }
}

#Preview {
    @StateObject var debugSettings = DebugStore()

    return DebugMenuView(debugSettings: debugSettings)
}

func OptionalBinding<T>(_ binding: Binding<T?>, _ defaultValue: T) -> Binding<T> {
    return Binding<T>(get: {
        return binding.wrappedValue ?? defaultValue
    }, set: {
        binding.wrappedValue = $0
    })
}

func ?? <T>(left: Binding<T?>, right: T) -> Binding<T> {
    return OptionalBinding(left, right)
}
