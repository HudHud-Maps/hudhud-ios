//
//  AppEnvironment.swift
//  HudHud
//
//  Created by Ali Hilal on 07/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

enum AppEnvironment: String, CaseIterable {
    case development = "dev"
    case staging
    case production = "prod"

    // MARK: Static Computed Properties

    static var inferred: AppEnvironment {
        #if DEBUG
            return .development

        #elseif targetEnvironment(simulator)
            return .development

        #else
            if Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") != nil {
                return .staging
            }

            guard let appStoreReceiptUrl = Bundle.main.appStoreReceiptURL else {
                return .development
            }

            if appStoreReceiptUrl.lastPathComponent.lowercased() == "sandboxreceipt" {
                return .staging
            }

            if appStoreReceiptUrl.path.lowercased().contains("simulator") {
                return .development
            }

            return .production
        #endif
    }
}
