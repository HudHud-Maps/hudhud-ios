//
//  DebugStore.swift
//  HudHud
//
//  Created by Alaa . on 12/05/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation
import OSLog
import SwiftUI

// MARK: - DebugStore

class DebugStore: ObservableObject {

    @AppStorage("routingHost") var routingHost: String = "gh-proxy.map.dev.hudhud.sa"
    @AppStorage("baseurl") var baseURL: String = "https://api.dev.hudhud.sa"
    @AppStorage("SFSymbolsMap") var customMapSymbols: Bool?

    @AppStorage("simulateRide") var simulateRide: Bool = UIApplication.environment == .development
    @AppStorage("streetViewQuality") var streetViewQuality: StreetViewQuality = .original
}

// MARK: - StreetViewQuality

enum StreetViewQuality: String, CaseIterable, Codable, Hashable, Identifiable {
    case original
    case medium
    case low

    // MARK: Computed Properties

    var id: Self {
        return self
    }

    var size: CGSize? {
        switch self {
        case .original:
            return nil
        case .medium:
            return CGSize(width: 6752, height: 3376)
        case .low:
            return CGSize(width: 6752, height: 3376)
        }
    }

    var quality: Int? {
        switch self {
        case .original:
            return nil
        case .medium:
            return 85
        case .low:
            return 50
        }
    }

    var approximateFileSize: UInt64 {
        switch self {
        case .original:
            return 5_753_893
        case .medium:
            return 1_803_411
        case .low:
            return 788_736
        }
    }
}

// MARK: - DeviceSupport

enum DeviceSupport {

    // Based on table from: https://developer.apple.com/metal/Metal-Feature-Set-Tables.pdf
    static func maxiumSupportedTextureSize() -> CGSize {
        var maxLength: CGFloat = 4096

        guard let device = MTLCreateSystemDefaultDevice() else {
            return .square(maxLength)
        }

        if device.supportsFamily(.apple1) || device.supportsFamily(.apple2) {
            maxLength = 8192 // A7 and A8 chips
        } else {
            maxLength = 16384 // A9 and later chips
        }
        return .square(maxLength)
    }

    static func clipToMaximumSupportedTextureSize(_ size: CGSize) -> CGSize {
        let deviceLimit = Self.maxiumSupportedTextureSize()
        var currentSize = size

        // Repeat halving the size until it fits within the device limit
        while currentSize.width > deviceLimit.width || currentSize.height > deviceLimit.height {
            // Halve the size while maintaining the aspect ratio
            currentSize = CGSize(width: currentSize.width / 2, height: currentSize.height / 2)
        }

        return currentSize
    }
}
