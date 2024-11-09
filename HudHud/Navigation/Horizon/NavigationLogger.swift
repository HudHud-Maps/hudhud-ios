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
        case debug, info, error, success

        // MARK: Computed Properties

        var prefix: String {
            switch self {
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .error: return "❌"
            case .success: return "✅"
            }
        }
    }

    // MARK: Static Properties

    static var isEnabled = true

    private static var indentationLevel = 0
    private static let indentationString = "│   "

    // MARK: Static Functions

    static func beginScope(_ description: String) {
        guard self.isEnabled else { return }
        let indent = String(repeating: indentationString, count: indentationLevel)
        let prefix = self.indentationLevel == 0 ? "┌─" : "├─"
        print("\(indent)\(prefix) \(description)")
        self.indentationLevel += 1
    }

    static func endScope() {
        guard self.isEnabled else { return }
        self.indentationLevel -= 1
        self.indentationLevel = max(0, self.indentationLevel)
        let indent = String(repeating: indentationString, count: indentationLevel)
        print("\(indent)└─")
    }

    static func beginFrame(_ description: String) {
        guard self.isEnabled else { return }
        print("\n📍 ═══════════ \(description) ═══════════")
        self.indentationLevel = 0
    }

    static func endFrame() {
        guard self.isEnabled else { return }
        print("════════════ End Frame ════════════\n")
    }

    static func log(_ message: String, level: LogLevel = .info) {
        guard self.isEnabled else { return }
        let indent = String(repeating: indentationString, count: indentationLevel)

        if message.contains(":") {
            let components = message.split(separator: ":", maxSplits: 1)
            if components.count == 2 {
                print("\(indent)│ \(level.prefix) \(components[0]): \(components[1].trimmingCharacters(in: .whitespaces))")
                return
            }
        }

        print("\(indent)│ \(level.prefix) \(message)")
    }

    static func logValue(_ key: String, _ value: Any) {
        self.log("\(key): \(value)")
    }

    static func logSuccess(_ message: String) {
        self.log(message, level: .success)
    }
}
