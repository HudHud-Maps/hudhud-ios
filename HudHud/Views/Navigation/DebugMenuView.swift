//
//  DebugMenuView.swift
//  HudHud
//
//  Created by Alaa . on 12/05/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import MapboxCoreNavigation
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
            Section(header: Text("User is on Route")) {
                TextField("In meters", text: self.$debugSettings.userLocationSnappingDistance.string)
                    .keyboardType(.asciiCapableNumberPad)
                    .disableAutocorrection(true)
            }

            Section(header: Text("Base URL"), footer: Text("Note: Changing the URL requires restarting the app for the changes to take effect.")) {
                TextField("Base URL", text: self.$debugSettings.baseURL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onChange(of: self.debugSettings.baseURL) { newValue in
                        if newValue.isEmpty {
                            self.debugSettings.baseURL = "https://api.dev.hudhud.sa"
                        } else {
                            self.debugSettings.baseURL = newValue
                        }
                    }
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

            Section(header: Text("SF Symbols on Map")) {
                Toggle(isOn: self.$debugSettings.customMapSymbols ?? false) {
                    Text("Use SF Symbols for POIs on map")
                }
            }
        }
        .navigationTitle("Debug Menu")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Reset") {
                    self.debugSettings.routingHost = "gh.map.dev.hudhud.sa"
                    self.debugSettings.baseURL = "https://api.dev.hudhud.sa"
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    self.dismiss()
                }
            }
        }
        .onChange(of: self.debugSettings.userLocationSnappingDistance) { newMaximumDistance in
            RouteControllerUserLocationSnappingDistance = newMaximumDistance
        }
    }
}

#Preview {
    @StateObject var debugSettings = DebugStore()

    return DebugMenuView(debugSettings: debugSettings)
}

func optionalBinding<T>(_ binding: Binding<T?>, _ defaultValue: T) -> Binding<T> {
    return Binding<T>(get: {
        return binding.wrappedValue ?? defaultValue
    }, set: {
        binding.wrappedValue = $0
    })
}

func ?? <T>(left: Binding<T?>, right: T) -> Binding<T> {
    return optionalBinding(left, right)
}

private extension CLLocationDistance {
    var string: String {
        get {
            "\(self)"
        }
        set {
            if let result = CLLocationDistance(newValue) {
                self = result
            }
        }
    }
}
