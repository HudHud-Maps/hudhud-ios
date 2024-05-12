//
//  DebugMenuView.swift
//  HudHud
//
//  Created by Alaa . on 12/05/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct DebugMenuView: View {
	@Environment(\.dismiss) private var dismiss
	@ObservedObject var debugSettings: DebugSettings
	@State private var showingError = false

	var body: some View {
		NavigationStack {
			Form {
				Section(header: Text("Routing Configuration")) {
					TextField("Routing URL", text: self.$debugSettings.routingURL)
						.autocapitalization(.none)
						.disableAutocorrection(true)
						.textFieldStyle(RoundedBorderTextFieldStyle())
					if !self.debugSettings.isURLValid {
						Text("Invalid or unreachable URL")
							.foregroundColor(.red)
					}
				}

				Section(header: Text("Simulation")) {
					Toggle(isOn: self.$debugSettings.simulateRide) {
						Text("Simulate Ride during Navigation")
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
			.alert(isPresented: self.$showingError) {
				Alert(title: Text("Invalid URL"), message: Text("Please enter a valid URL."), dismissButton: .default(Text("OK")))
			}
		}
	}
}

#Preview {
	@StateObject var debugSettings = DebugSettings()

	return DebugMenuView(debugSettings: debugSettings)
}
