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
	private var motionManager: CMMotionManager
	private var lastPositions: [Position] = []
	private let smoothingPasses = 10

	@Published var motion: CMDeviceMotion?
	@Published var position: Position?

	// MARK: - Lifecycle

	init() {
		self.motionManager = CMMotionManager()
		self.motionManager.deviceMotionUpdateInterval = 1.0 / Double(UIScreen.main.maximumFramesPerSecond)
		self.start()
	}

	deinit {
		self.motionManager.stopGyroUpdates()
	}

	// MARK: - Internal

	@objcMembers
	final class Position: NSObject, Averageable {
		var heading: Double
		var pitch: Double

		static var zero: MotionViewModel.Position = .init(heading: 0, pitch: 0)

		// MARK: - Lifecycle

		init(heading: Double, pitch: Double) {
			self.heading = heading
			self.pitch = pitch
		}

		// MARK: - Internal

		override func copy() -> Any {
			return Position(heading: self.heading, pitch: self.pitch)
		}
	}

	// MARK: - Private

	private func start() {
		guard self.motionManager.isDeviceMotionAvailable else {
			print("Gyroscope is not available on this device.")
			return
		}

		self.motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical, to: .main) { [weak self] motionData, error in
			guard let self else { return }
			guard error == nil, let motionData else {
				print("Error reading gyroscope: \(error?.localizedDescription ?? "<nil>")")
				return
			}
			self.motion = motionData

			let newPosition = Position(heading: motionData.attitude.yaw.toDegrees(),
									   pitch: motionData.attitude.pitch)
			self.lastPositions.append(newPosition)

			if self.lastPositions.count >= self.smoothingPasses {
				self.lastPositions.removeFirst()
				self.position = self.lastPositions.average()
			}
		}
	}
}

// MARK: - DebugStreetView

struct DebugStreetView: View {

	@ObservedObject var viewModel = MotionViewModel()

	var body: some View {
		VStack {
			Text("Gyroscope Data")
//			if let position = self.viewModel.position {
//				Text("Heading: \(String(format: "%4.1f", position.heading))")
//					.monospaced()
//				Text("Pitch: \(String(format: "%4.1f", position.pitch))")
//					.monospaced()
			if let motion = self.viewModel.motion {
				Text("X: \(String(format: "%4.3f", motion.attitude.quaternion.x))")
					.monospaced()
				Text("Y: \(String(format: "%4.3f", motion.attitude.quaternion.y))")
					.monospaced()
				Text("Z: \(String(format: "%4.3f", motion.attitude.quaternion.z))")
					.monospaced()
				Text("W: \(String(format: "%4.3f", motion.attitude.quaternion.w))")
					.monospaced()
			} else {
				Text("Loading")
			}
		}
	}
}

#Preview {
	DebugStreetView()
}
