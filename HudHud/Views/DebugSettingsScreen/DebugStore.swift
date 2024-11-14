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

    @AppStorage("routingHost") var routingHost: String = "gh.map.dev.hudhud.sa"
    @AppStorage("baseurl") var baseURL: String = "https://api.dev.hudhud.sa"
    @AppStorage("SFSymbolsMap") var customMapSymbols: Bool?

    @AppStorage("simulateRide") var simulateRide: Bool = UIApplication.environment == .development
    @AppStorage("streetViewQuality") var streetViewQuality: StreetViewQuality = .original
    @AppStorage("showLocationDiagmosticLogs") var showLocationDiagmosticLogs: Bool = false
    @AppStorage("showDrivenPartOfTheRoute") var showDrivenPartOfTheRoute: Bool = false
}

// MARK: - StreetViewQuality

enum StreetViewQuality: String, CaseIterable, Codable, Hashable, Identifiable {
    case original
    case medium
    case low
    case webp1
    case webp2

    // MARK: Computed Properties

    var id: Self {
        return self
    }

    var size: ImageSize? {
        switch self {
        case .original:
            return nil
        case .medium:
            return ImageSize(width: 6752, height: 3376)
        case .low:
            return ImageSize(width: 6752, height: 3376)
        case .webp1:
            return ImageSize(width: 5500, height: 2750)
        case .webp2:
            return ImageSize(width: 5500, height: 2750)
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
        case .webp1:
            return 80
        case .webp2:
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
        case .webp1:
            return 456_222
        case .webp2:
            return 222_454
        }
    }

    var format: String? {
        switch self {
        case .original:
            return nil
        case .medium:
            return "jpeg"
        case .low:
            return "jpeg"
        case .webp1:
            return "webp"
        case .webp2:
            return "webp"
        }
    }
}
