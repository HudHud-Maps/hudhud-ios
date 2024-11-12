//
//  Direction.swift
//  HudHud
//
//  Created by Ali Hilal on 06/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation

// MARK: - Direction

enum Direction: Double {
    case north = 0
    case east = 90
    case south = 180
    case west = 270

    // MARK: Static Properties

    static let tolerance: CLLocationDirection = 45

    // MARK: Computed Properties

    var degrees: CLLocationDirection { rawValue }

    var opposite: Direction {
        switch self {
        case .north: return .south
        case .south: return .north
        case .east: return .west
        case .west: return .east
        }
    }

    // MARK: Static Functions

    static func from(degrees: CLLocationDirection) -> Direction? {
        let normalized = degrees.truncatingRemainder(dividingBy: 360)
        return Direction.allCases.first { direction in
            abs(normalized - direction.degrees) <= self.tolerance
        }
    }

    // MARK: Functions

    func matches(_ course: CLLocationDirection) -> Bool {
        let diff = abs(course - self.degrees)
        return diff <= Self.tolerance || diff >= (360 - Self.tolerance)
    }
}

// MARK: - CaseIterable

extension Direction: CaseIterable {}
