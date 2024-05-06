//
//  PadSheetGesture.swift
//  HudHud
//
//  Created by Alaa . on 29/04/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SwiftUI

struct PadSheetGesture<Content: View>: View {
	let subview: Content
	let screenHeight = UIScreen.main.bounds.height
	@State private var sheetSize: CGSize = .zero
	@State var offsetY: CGFloat = 0

	var body: some View {
		self.subview
			.offset(y: self.sheetSize.height + self.offsetY)
			.gesture(
				DragGesture()
					.onChanged { value in
						self.sheetSize = value.translation
					}
					.onEnded { _ in
						withAnimation(.spring()) {
							let snap = self.sheetSize.height + self.offsetY

							if snap > self.screenHeight / 2 {
								self.offsetY = self.screenHeight - self.screenHeight / 9.5
							} else {
								self.offsetY = 0
							}
							self.sheetSize = .zero
						}
					})
	}

	// MARK: - Lifecycle

	init(@ViewBuilder subview: () -> Content) {
		self.subview = subview()
	}

}
