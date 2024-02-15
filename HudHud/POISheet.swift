//
//  POISheet.swift
//  HudHud
//
//  Created by Patrick Kladek on 02.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation
import POIService
import SFSafeSymbols
import SwiftUI
import ToursprungPOI

struct POISheet: View {

	let poi: POI
	@Binding var isShown: Bool
	let onStart: () -> Void
	let onMore: () -> Void

	var body: some View {
		NavigationStack {
			VStack(alignment: .leading) {
				HStack(alignment: .top) {
					VStack {
						Text(self.poi.name)
							.font(.title.bold() )
							.frame(maxWidth: .infinity, alignment: .leading)

						Text(self.poi.type)
							.font(.footnote)
							.frame(maxWidth: .infinity, alignment: .leading)
							.padding(.bottom, 8)
					}

					Button(action: {
						self.isShown = false
					}, label: {
						ZStack {
							Circle()
								.fill(.quaternary)
								.frame(width: 30, height: 30)

							Image(systemSymbol: .xmark)
								.font(.system(size: 15, weight: .bold, design: .rounded))
								.foregroundColor(.white)
						}
						.padding(8)
						.contentShape(Circle())
					})
					.buttonStyle(PlainButtonStyle())
					.accessibilityLabel(Text("Close"))
				}
				.padding([.top, .leading, .trailing])

				HStack {
					Button(action: self.onStart) {
						VStack(spacing: 2) {
							Image(systemSymbol: .carFill)
							Text("Start")
						}
						.frame(maxWidth: .infinity)
						.padding(.vertical, 2)
					}
					.buttonStyle(.borderedProminent)

					Button(action: self.onMore) {
						VStack(spacing: 2) {
							Image(systemSymbol: .phoneFill)
							Text("Call")
						}
						.frame(maxWidth: .infinity)
						.padding(.vertical, 2)
					}
					.buttonStyle(.bordered)

					Button(action: self.onMore) {
						VStack(spacing: 2) {
							Image(systemSymbol: .safariFill)
							Text("Web")
						}
						.frame(maxWidth: .infinity)
						.padding(.vertical, 2)
					}
					.buttonStyle(.bordered)

					Button(action: self.onMore) {
						VStack(spacing: 2) {
							Image(systemSymbol: .phoneFill)
							Text("More")
						}
						.frame(maxWidth: .infinity)
						.padding(.vertical, 2)
					}
					.buttonStyle(.bordered)
				}
				.padding(.horizontal)

				DictionaryView(dictionary: self.poi.userInfo)
			}
		}
	}
}

@available(iOS 17, *)
#Preview(traits: .sizeThatFitsLayout) {
	let poi = POI(element: .starbucksKualaLumpur)!	// swiftlint:disable:this force_unwrapping
	return POISheet(poi: poi, isShown: .constant(true)) {
		print("start")
	} onMore: {
		print("more")
	}
}
