//
//  PadSheetView.swift
//  HudHud
//
//  Created by Alaa . on 29/04/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct PadSheetView<Content: View>: View {
	let screenHeight = UIScreen.main.bounds.height
	let subview: Content

	var body: some View {
		VStack {
			self.subview
				.frame(width: 300, height: self.screenHeight)
				.background(Color.white)
				.cornerRadius(16)
				.overlay(alignment: .top) {
					Rectangle()
						.frame(width: 40, height: 6)
						.foregroundColor(Color.secondary)
						.cornerRadius(3)
						.padding(5)
				}
		}
	}

	// MARK: - Lifecycle

	init(@ViewBuilder subview: () -> Content) {
		self.subview = subview()
	}
}

#Preview {
	PadSheetView {}
}
