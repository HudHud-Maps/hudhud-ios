//
//  TouchManager.swift
//  HudHud
//
//  Created by Fatima Aljaber on 01/07/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Combine
import Foundation
import SwiftUI
import TouchVisualizer

class TouchManager: ObservableObject {

    static let shared = TouchManager()

    private var window: UIWindow?
    @Published var isTouchVisualizerEnabled: Bool

    // MARK: - Lifecycle

    init() {
        self.isTouchVisualizerEnabled = false
        self.setDefaultTouchVisualizerSetting()
    }

    // MARK: - Internal

    func updateVisualizer(isScreenRecording: Bool) {
        if self.isTouchVisualizerEnabled, isScreenRecording {
            guard let window = getKeyWindow() else { return }
            var config = Configuration()
            config.color = .red
            config.showsTouchRadius = true
            Visualizer.start(config, in: window)
        } else {
            Visualizer.stop()
        }
    }

    // MARK: - Private

    private func getKeyWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }

    private func setDefaultTouchVisualizerSetting() {
        switch UIApplication.environment {
        case .simulator, .testFlight, .development:
            self.isTouchVisualizerEnabled = true
            UserDefaults.standard.set(true, forKey: "touchEnabled")
        case .appStore:
            self.isTouchVisualizerEnabled = false
            UserDefaults.standard.set(false, forKey: "touchEnabled")
        }
    }
}
