//
//  DebugStreetView.swift
//  HudHud
//
//  Created by Patrick Kladek on 26.03.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreMotion
import SwiftUI

// MARK: - MotionViewModel

class MotionViewModel: ObservableObject {
	@Published var position: Position = .zero
	@Published var positionOffet: Position?

	// MARK: - Internal

	struct Position: Equatable {
		var heading: Double
		var pitch: Double

		static var zero: MotionViewModel.Position = .init(heading: 0, pitch: 0)

		// MARK: - Lifecycle

		init(heading: Double, pitch: Double) {
			self.heading = heading.wrap(min: 0, max: 360)
			self.pitch = Double.minimum(pitch, 180)
		}

		// MARK: - Internal

		static func + (left: Position, right: Position) -> Position {
			let pitch = (left.pitch + right.pitch).limit(upper: 180)

			return Position(heading: left.heading + right.heading,
							pitch: pitch)
		}
	}
}

// MARK: - DebugStreetView

struct DebugStreetView: View {

	@StateObject var viewModel = MotionViewModel()

	var body: some View {
		// This here works as expected
//		RoundedRectangle(cornerRadius: 10)
//			.fill(Color.yellow)
//			.frame(height: 300)
//			.overlay(alignment: .top) {
//				ZStack {
//					Color.red
//					Text("Debug StreetView")
//						.foregroundColor(.white)
//				}
//				.clipShape(RoundedRectangle(cornerRadius: 10))
//			}
//			.padding(.horizontal, 20)

		// This is ignoring the safeAreaInsets
		VStack(alignment: .trailing) {
			Text("Debug Street View")
			Text("Heading: \(String(format: "%5.1f°", self.viewModel.position.heading))")
				.monospaced()
			Text("Pitch: \(String(format: "%5.1f ", self.viewModel.position.pitch))")
				.monospaced()
		}
		.background(.red)
		.gesture(DragGesture(minimumDistance: 10, coordinateSpace: .global)
			.onChanged { value in
				if let dragStartOffset = viewModel.positionOffet {
					self.viewModel.position = dragStartOffset + MotionViewModel.Position(heading: value.translation.width,
																						 pitch: -value.translation.height)
				} else {
					self.viewModel.positionOffet = self.viewModel.position
				}
			}
			.onEnded { _ in
				self.viewModel.positionOffet = nil
			}
		)
	}
}

#Preview {
	DebugStreetView()
}
