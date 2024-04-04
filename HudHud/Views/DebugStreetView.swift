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

final class MotionViewModel: ObservableObject {
	enum Size: CaseIterable {
		case compact
		case fullscreen
	}

	@Published var position: Position = .initial
	@Published var positionOffet: Position?
	@Published var size: Size = .compact

	// MARK: - Lifecycle

	init(position: Position = .initial, positionOffet: Position? = nil, size: Size = .compact) {
		self.position = position
		self.positionOffet = positionOffet
		self.size = size
	}

	// MARK: - Internal

	struct Position: Equatable {
		var heading: Double
		var pitch: Double

		static var initial = MotionViewModel.Position(heading: 0, pitch: 90)

		// MARK: - Lifecycle

		init(heading: Double, pitch: Double) {
			self.heading = heading
			self.pitch = Double.minimum(pitch, 180)
		}

		// MARK: - Internal

		static func + (left: Position, right: Position) -> Position {
			let pitch = (left.pitch + right.pitch).limit(upper: 180)

			return Position(heading: left.heading + right.heading,
							pitch: pitch)
		}

		static func * (left: Position, right: Double) -> Position {
			return Position(heading: left.heading * right,
							pitch: left.pitch * right)
		}
	}

	func adding(translation: CGSize) {
		if let dragStartOffset = self.positionOffet {
			// try to mimic scrolling so your finger stays below the initial tap point
			// needs fine tuning once we have the StreetView WebView
			let scaleFactor = 0.25

			let newHeading = (dragStartOffset.heading + (translation.width * scaleFactor)).wrap(min: 0, max: 360)
			let newPitch = (dragStartOffset.pitch + (translation.height * scaleFactor)).limit(upper: 180)

			self.position.heading = newHeading
			self.position.pitch = newPitch
		} else {
			self.positionOffet = self.position
		}
	}
}

// MARK: - DebugStreetView

struct DebugStreetView: View {

	@StateObject var viewModel: MotionViewModel

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
					self.viewModel.positionOffet = nil
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
