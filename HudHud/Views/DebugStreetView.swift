//
//  DebugStreetView.swift
//  HudHud
//
//  Created by Patrick Kladek on 26.03.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreMotion
import SwiftUI

// MARK: - DebugStreetView

struct DebugStreetView: View {

	@ObservedObject var viewModel: MotionViewModel

	var body: some View {
		ViewThatFits {
			VStack(alignment: .trailing) {
				Text("Heading: \(String(format: "%5.1f°", self.viewModel.position.heading))")
					.monospaced()
					.animation(.none)
				Text("Pitch: \(String(format: "%5.1f ", self.viewModel.position.pitch))")
					.monospaced()
					.animation(.none)
			}
			.frame(height: 300)
			.frame(maxWidth: .infinity, maxHeight: self.viewModel.size == .compact ? 300 : .infinity)
			.background(.gray, ignoresSafeAreaEdges: [])
			.foregroundStyle(.white)
			.clipShape(RoundedRectangle(cornerRadius: 12))
			.gesture(DragGesture(minimumDistance: 10, coordinateSpace: .global)
				.onChanged { value in
					self.viewModel.adding(translation: value.translation)
				}
				.onEnded { _ in
					self.viewModel.endTranslation()
				}
			)
			.onTapGesture {
				self.viewModel.size.selectNext()
			}
		}
		.padding(.horizontal)
		.animation(.easeInOut, value: self.viewModel.size)
	}
}

#Preview {
	Rectangle()
		.fill(Color.yellow)
		.ignoresSafeArea()
		.safeAreaInset(edge: .top, alignment: .center) {
			DebugStreetView(viewModel: MotionViewModel())
		}
}
