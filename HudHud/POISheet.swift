//
//  POISheet.swift
//  HudHud
//
//  Created by Patrick Kladek on 02.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SwiftUI

struct POISheet: View {

	var onStart: () -> Void
	var onMore: () -> Void

	var body: some View {
		VStack(alignment: .leading) {
			HStack(alignment: .top) {
				VStack {
					Text("Ketch Up - Dubai")
						.font(.title.bold() )
						.frame(maxWidth: .infinity, alignment: .leading)

					Text("Restaurant")
						.font(.footnote)
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding(.bottom, 8)
				}
				
				Button(action: {
					print("close")
				}, label: {
					ZStack {
						Circle()
							.fill(.secondary)
							.frame(width: 30, height: 30)

						Image(systemName: "xmark")
							.font(.system(size: 15, weight: .bold, design: .rounded))
							.foregroundColor(.secondary)
					}
					.padding(8)
					.contentShape(Circle())
				})
				.buttonStyle(PlainButtonStyle())
				.accessibilityLabel(Text("Close"))
			}

			HStack {
				Button(action: onStart) {
					VStack(spacing: 2) {
						Image(systemName: "car.fill")
						Text("Start")
					}
					.frame(maxWidth: .infinity)
					.padding(.vertical, 2)
				}
				.buttonStyle(.borderedProminent)

				Button(action: onMore) {
					VStack(spacing: 2) {
						Image(systemName: "phone.fill")
						Text("Call")
					}
					.frame(maxWidth: .infinity)
					.padding(.vertical, 2)
				}
				.buttonStyle(.bordered)

				Button(action: onMore) {
					VStack(spacing: 2) {
						Image(systemName: "safari.fill")
						Text("Web")
					}
					.frame(maxWidth: .infinity)
					.padding(.vertical, 2)
				}
				.buttonStyle(.bordered)

				Button(action: onMore) {
					VStack(spacing: 2) {
						Image(systemName: "phone.fill")
						Text("More")
					}
					.frame(maxWidth: .infinity)
					.padding(.vertical, 2)
				}
				.buttonStyle(.bordered)
			}
		}
		.padding()

		Spacer()
	}
}

#Preview {
	POISheet {
		print("start")
	} onMore: {
		print("more")
	}
}
