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
