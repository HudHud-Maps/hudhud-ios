//
//  PredictionResult.swift
//  BackendService
//
//  Created by Patrick Kladek on 05.09.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import MapKit

// MARK: - PredictionResult

public enum PredictionResult: Hashable, Codable {
    case apple(completion: MKLocalSearchCompletion)
    case appleResolved
    case hudhud

    // MARK: Nested Types

    enum CodingKeys: CodingKey {
        case appleResolved
        case hudhud
    }
}
