//
//  ABCRouteConfigurationView.swift
//  HudHud
//
//  Created by Alaa . on 10/03/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI
import SFSafeSymbols

struct ABCRouteConfigurationView: View {
	@State var routes: [Route]
	var body: some View {
		VStack {
			List {
				ForEach(routes) { route in
					HStack {
						Image(systemSymbol: route == routes.first ? .location : .mappin)
							Text(route.name)
								.foregroundColor(.primary)
								.lineLimit(1)
								.minimumScaleFactor(0.5)
							Spacer()
							Image(systemSymbol: .circleGrid2x2Fill)
					}
					.foregroundColor(.secondary)
				}
				// List Adjustments
				.onMove(perform: moveAction)
				.onDelete { indexSet in
					routes.remove(atOffsets: indexSet)
				}
				.listRowBackground(Color(.quaternarySystemFill))
				// Add location button
				Button {
						routes.append(Route(name: "New Location"))
				} label: {
					HStack {
						Image(systemName: "plus")
							.foregroundColor(.secondary)
						Text("Add Location")
							.foregroundColor(.primary)
							.lineLimit(1)
							.minimumScaleFactor(0.5)
					}
				}
				.listRowBackground(Color(.quaternarySystemFill))
			}
		}
	}
	func moveAction(from source: IndexSet, to destination: Int) {
		routes.move(fromOffsets: source, toOffset: destination)
	}
}

#Preview {
	ABCRouteConfigurationView(routes: [
			  Route(name: "My Location"),
			  Route(name: "Second Location"),
			  Route(name: "Third Location")])
}
