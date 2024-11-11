//
//  UIApplication+Environment.swift
//  HudHud
//
//  Created by Patrick Kladek on 25.06.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import UIKit

public extension UIApplication {

    enum Environment: String, CaseIterable, Codable, Equatable {
        case simulator
        case development
        case testFlight
        case appStore
    }

    // MARK: - Properties

    nonisolated static var isSimulator: Bool {
        #if targetEnvironment(simulator)
            return true
        #else
            return false
        #endif
    }

    nonisolated static var environment: Environment {
        if self.isDebug {
            return .development
        } else if isTestFlight {
            return .testFlight
        } else {
            if self.isSimulator {
                return .simulator
            } else {
                return .appStore
            }
        }
    }
}

extension [UIApplication.Environment] {

    static var upToTestFlight: [UIApplication.Environment] = [.simulator, .development, .testFlight]
}

// MARK: - Private

private extension UIApplication {

    nonisolated static let isTestFlight = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"

    nonisolated static var isDebug: Bool {
        #if DEBUG
            return true
        #else
            return false
        #endif
    }

}
