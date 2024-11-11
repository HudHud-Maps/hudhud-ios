//
//  Measurement+Extensions.swift
//  HudHud
//
//  Created by Ali Hilal on 05/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

extension Measurement where UnitType == UnitLength {
    var meters: Double {
        return self.converted(to: .meters).value
    }

    var kilometers: Double {
        return self.converted(to: .kilometers).value
    }

    var centimeters: Double {
        return self.converted(to: .centimeters).value
    }

    var millimeters: Double {
        return self.converted(to: .millimeters).value
    }

    var inches: Double {
        return self.converted(to: .inches).value
    }

    var feet: Double {
        return self.converted(to: .feet).value
    }

    var yards: Double {
        return self.converted(to: .yards).value
    }

    var miles: Double {
        return self.converted(to: .miles).value
    }

    static func meters(_ value: Double) -> Measurement<UnitLength> {
        return Measurement(value: value, unit: .meters)
    }

    static func kilometers(_ value: Double) -> Measurement<UnitLength> {
        return Measurement(value: value, unit: .kilometers)
    }
}

extension Measurement where UnitType == UnitSpeed {
    var metersPerSecond: Double {
        return self.converted(to: .metersPerSecond).value
    }

    var kilometersPerHour: Double {
        return self.converted(to: .kilometersPerHour).value
    }

    var milesPerHour: Double {
        return self.converted(to: .milesPerHour).value
    }

    var knots: Double {
        return self.converted(to: .knots).value
    }

    static func metersPerSecond(_ value: Double) -> Measurement<UnitSpeed> {
        return Measurement(value: value, unit: .metersPerSecond)
    }

    static func kilometersPerHour(_ value: Double) -> Measurement<UnitSpeed> {
        return Measurement(value: value, unit: .kilometersPerHour)
    }

    static func milesPerHour(_ value: Double) -> Measurement<UnitSpeed> {
        return Measurement(value: value, unit: .milesPerHour)
    }

    static func knots(_ value: Double) -> Measurement<UnitSpeed> {
        return Measurement(value: value, unit: .knots)
    }
}

extension Measurement where UnitType == UnitAngle {
    var degrees: Double {
        return self.converted(to: .degrees).value
    }

    var radians: Double {
        return self.converted(to: .radians).value
    }

    var arcMinutes: Double {
        return self.converted(to: .arcMinutes).value
    }

    var arcSeconds: Double {
        return self.converted(to: .arcSeconds).value
    }

    static func degrees(_ value: Double) -> Measurement<UnitAngle> {
        return Measurement(value: value, unit: .degrees)
    }

    static func radians(_ value: Double) -> Measurement<UnitAngle> {
        return Measurement(value: value, unit: .radians)
    }

    static func arcMinutes(_ value: Double) -> Measurement<UnitAngle> {
        return Measurement(value: value, unit: .arcMinutes)
    }

    static func arcSeconds(_ value: Double) -> Measurement<UnitAngle> {
        return Measurement(value: value, unit: .arcSeconds)
    }
}

extension Measurement where UnitType == UnitDuration {
    var seconds: Double {
        return self.converted(to: .seconds).value
    }

    var minutes: Double {
        return self.converted(to: .minutes).value
    }

    var hours: Double {
        return self.converted(to: .hours).value
    }

    static func seconds(_ value: Double) -> Measurement<UnitDuration> {
        return Measurement(value: value, unit: .seconds)
    }

    static func minutes(_ value: Double) -> Measurement<UnitDuration> {
        return Measurement(value: value, unit: .minutes)
    }

    static func hours(_ value: Double) -> Measurement<UnitDuration> {
        return Measurement(value: value, unit: .hours)
    }
}

extension Measurement where UnitType == UnitArea {
    var squareMeters: Double {
        return self.converted(to: .squareMeters).value
    }

    var squareKilometers: Double {
        return self.converted(to: .squareKilometers).value
    }

    var squareFeet: Double {
        return self.converted(to: .squareFeet).value
    }

    var acres: Double {
        return self.converted(to: .acres).value
    }

    static func squareMeters(_ value: Double) -> Measurement<UnitArea> {
        return Measurement(value: value, unit: .squareMeters)
    }

    static func squareKilometers(_ value: Double) -> Measurement<UnitArea> {
        return Measurement(value: value, unit: .squareKilometers)
    }

    static func squareFeet(_ value: Double) -> Measurement<UnitArea> {
        return Measurement(value: value, unit: .squareFeet)
    }

    static func acres(_ value: Double) -> Measurement<UnitArea> {
        return Measurement(value: value, unit: .acres)
    }
}
