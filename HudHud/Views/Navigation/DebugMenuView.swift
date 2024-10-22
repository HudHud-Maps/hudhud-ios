//
//  DebugMenuView.swift
//  HudHud
//
//  Created by Alaa . on 12/05/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
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

            Section(header: Text("Base URL"), footer: Text("Note: Changing the URL requires restarting the app for the changes to take effect.")) {
                TextField("Base URL", text: self.$debugSettings.baseURL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onChange(of: self.debugSettings.baseURL) { _, newValue in
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

            self.streetViewQualitySection
        }
        .navigationTitle("Debug Menu")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Reset") {
                    self.debugSettings.routingHost = "gh-proxy.map.dev.hudhud.sa"
                    self.debugSettings.baseURL = "https://api.dev.hudhud.sa"
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    self.dismiss()
                }
            }
        }
    }

    var streetViewQualitySection: some View {
        Section {
            Picker("Quality", selection: self.$debugSettings.streetViewQuality) {
                ForEach(StreetViewQuality.allCases) {
                    Text($0.rawValue.localizedCapitalized)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("StreetView Quality")
        } footer: {
            Grid(alignment: .leading, horizontalSpacing: nil) {
                ForEach(StreetViewQuality.allCases) { quality in
                    GridRow {
                        Text("• \(quality.rawValue.localizedCapitalized)")
                            .gridColumnAlignment(.leading)
                        let size = quality.size ?? CGSize(width: 13504, height: 6752)
                        Text(size.width.formatted() + " x " + size.height.formatted())
                            .gridColumnAlignment(.trailing)
                        if let percentage = quality.quality {
                            Text("@")
                            Text((Double(percentage) / 100.0).formatted(.percent))
                                .gridColumnAlignment(.trailing)
                        } else {
                            Text("")
                            Text("")
                        }
                        Text("Size:")
                        Text(quality.approximateFileSize.formatted(.byteCount(style: .file)))
                            .gridColumnAlignment(.trailing)
                    }
                    .lineLimit(0)
                    .monospacedDigit()
                }
            }
        }
    }
}

#Preview {
    @Previewable @StateObject var debugSettings = DebugStore()

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
