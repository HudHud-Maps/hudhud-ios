//
//  TouchManager.swift
//  HudHud
//
//  Created by Fatima Aljaber on 01/07/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Combine
import Foundation
import OSLog
import SwiftUI
import TouchVisualizer

// MARK: - TouchManager

class TouchManager: ObservableObject {

    // MARK: Static Properties

    static let shared = TouchManager()

    // MARK: Properties

    @AppStorage("isTouchVisualizerEnabled") var isTouchVisualizerEnabled: Bool?

    private var window: UIWindow?
    private var cancellable: AnyCancellable?

    // MARK: Computed Properties

    var defaultTouchVisualizerSetting: Bool {
        switch UIApplication.environment {
        case .simulator, .testFlight, .development:
            return true
        case .appStore:
            return false
        }
    }

    // MARK: Lifecycle

    init() {
        self.cancellable = NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)
            .sink { screen in
                if let screen = screen.object as? UIScreen {
                    self.updateVisualizer(isScreenRecording: screen.isCaptured)
                    Logger.mapInteraction.log("\(screen.isCaptured ? "Started recording screen" : "Stopped recording screen")")
                }
            }
    }

    // MARK: Functions

    // MARK: - Internal

    // MARK: - TouchManager

    func updateVisualizer(isScreenRecording: Bool) {
        let isTouchVisualizerEnabled = self.isTouchVisualizerEnabled ?? self.defaultTouchVisualizerSetting

        if isTouchVisualizerEnabled, isScreenRecording {
            guard let window = self.getKeyWindow() else { return }

            var config = Configuration()
            config.color = .red
            config.showsTouchRadius = true
            Visualizer.start(config, in: window)
        } else {
            Visualizer.stop()
        }
    }
}

// MARK: - Private

private extension TouchManager {

    func getKeyWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }
}
