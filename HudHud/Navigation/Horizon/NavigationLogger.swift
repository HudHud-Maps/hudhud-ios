//
//  NavigationLogger.swift
//  HudHud
//
//  Created by Ali Hilal on 09/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

enum NavigationLogger {

    // MARK: Nested Types

    enum LogLevel {
        case debug, info, error

        // MARK: Computed Properties

        var prefix: String {
            switch self {
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .error: return "⛔️"
            }
        }
    }

    // MARK: Static Properties

    static var isEnabled = false

    private static var indentationLevel = 0
    private static let indentationString = "    "

    // MARK: Static Functions

    static func beginFrame(_ description: String) {
        guard self.isEnabled else { return }
        print("\n📍 -------- \(description) --------")
        self.indentationLevel = 0
    }

    static func endFrame() {
        guard self.isEnabled else { return }
        print("-------- End Frame --------\n")
    }

    static func beginScope(_ description: String) {
        guard self.isEnabled else { return }
        let indent = String(repeating: indentationString, count: indentationLevel)
        print("\(indent)⤵️ \(description) {")
        self.indentationLevel += 1
    }

    static func endScope() {
        guard self.isEnabled else { return }
        self.indentationLevel -= 1
        self.indentationLevel = max(0, self.indentationLevel)
        let indent = String(repeating: indentationString, count: indentationLevel)
        print("\(indent)}")
    }

    static func log(_ message: String, level: LogLevel = .info) {
        guard self.isEnabled else { return }
        let indent = String(repeating: indentationString, count: indentationLevel)
        print("\(indent)\(level.prefix) \(message)")
    }
}
