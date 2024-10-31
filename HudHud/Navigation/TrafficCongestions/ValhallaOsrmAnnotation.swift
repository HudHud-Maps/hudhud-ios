//
//  ValhallaOsrmAnnotation.swift
//  HudHud
//
//  Created by Ali Hilal on 30/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import FerrostarCore

struct ValhallaOsrmAnnotation: Decodable {

    // MARK: Nested Types

    enum CodingKeys: String, CodingKey {
        case speedLimit = "maxspeed"
        case speed
        case distance
        case duration
        case congestion
        case congestionNumeric = "congestion_numeric"
    }

    // MARK: Properties

    /// The speed limit for the current line segment.
    public let speedLimit: MaxSpeed?

    public let speed: Double?

    public let distance: Double?

    public let duration: Double?

    public let congestion: String?

    public let congestionNumeric: Int?
}
