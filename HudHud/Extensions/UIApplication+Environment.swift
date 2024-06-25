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

    nonisolated static var environment: Environment {
        if self.isDebug {
            return .development
        } else if isTestFlight {
            return .testFlight
        } else {
            return .appStore
        }
    }
}
