//
//  UIApplication+Environment.swift
//  HudHud
//
//  Created by Patrick Kladek on 25.06.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import UIKit

public extension UIApplication {

    enum Environment: String {
        case development
        case testFlight
        case appStore
        case simulator
    }

    // MARK: - Properties

    private nonisolated static let isTestFlight = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    private nonisolated static var isDebug: Bool {
        #if DEBUG
            return true
        #else
            return false
        #endif
    }

    private nonisolated static var isSimulator: Bool {
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
