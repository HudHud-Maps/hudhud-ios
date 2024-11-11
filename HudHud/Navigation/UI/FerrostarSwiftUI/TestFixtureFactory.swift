//
//  TestFixtureFactory.swift
//  HudHud
//
//  Created by Ali Hilal on 03.11.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

/// Various helpers that generate views for previews.

import FerrostarCoreFFI
import Foundation

// MARK: - TestFixtureFactory

protocol TestFixtureFactory {
    associatedtype Output
    func build(_ n: Int) -> Output
}

extension TestFixtureFactory {
    func buildMany(_ n: Int) -> [Output] {
        (0 ... n).map { build($0) }
    }
}

// MARK: - VisualInstructionContentFactory

struct VisualInstructionContentFactory: TestFixtureFactory {

    // MARK: Properties

    public var textBuilder: (Int) -> String = { n in RoadNameFactory().build(n) }

    // MARK: Lifecycle

    public init() {}

    // MARK: Functions

    public func text(_ builder: @escaping (Int) -> String) -> Self {
        var copy = self
        copy.textBuilder = builder
        return copy
    }

    public func build(_ n: Int = 0) -> VisualInstructionContent {
        VisualInstructionContent(text: self.textBuilder(n),
                                 maneuverType: .turn,
                                 maneuverModifier: .left,
                                 roundaboutExitDegrees: nil,
                                 laneInfo: nil)
    }
}

// MARK: - VisualInstructionFactory

struct VisualInstructionFactory: TestFixtureFactory {

    // MARK: Properties

    public var primaryContentBuilder: (Int) -> VisualInstructionContent = { n in
        VisualInstructionContentFactory().build(n)
    }

    public var secondaryContentBuilder: (Int) -> VisualInstructionContent? = { _ in nil }

    // MARK: Lifecycle

    public init() {}

    // MARK: Functions

    public func secondaryContent(_ builder: @escaping (Int) -> VisualInstructionContent) -> Self {
        var copy = self
        copy.secondaryContentBuilder = builder
        return copy
    }

    public func build(_ n: Int = 0) -> VisualInstruction {
        VisualInstruction(primaryContent: self.primaryContentBuilder(n),
                          secondaryContent: self.secondaryContentBuilder(n),
                          subContent: nil,
                          triggerDistanceBeforeManeuver: 42.0)
    }
}

// MARK: - RouteStepFactory

struct RouteStepFactory: TestFixtureFactory {

    // MARK: Properties

    public var visualInstructionBuilder: (Int) -> VisualInstruction = { n in VisualInstructionFactory().build(n) }
    public var roadNameBuilder: (Int) -> String = { n in RoadNameFactory().build(n) }

    // MARK: Lifecycle

    public init() {}

    // MARK: Functions

    public func build(_ n: Int = 0) -> RouteStep {
        RouteStep(geometry: [],
                  distance: 100,
                  duration: 99,
                  roadName: self.roadNameBuilder(n),
                  instruction: "Walk west on \(self.roadNameBuilder(n))",
                  visualInstructions: [self.visualInstructionBuilder(n)],
                  spokenInstructions: [],
                  annotations: nil)
    }
}

// MARK: - RoadNameFactory

struct RoadNameFactory: TestFixtureFactory {

    // MARK: Properties

    public var baseNameBuilder: (Int) -> String = { _ in "Ave" }

    // MARK: Lifecycle

    public init() {}

    // MARK: Functions

    public func baseName(_ builder: @escaping (Int) -> String) -> Self {
        var copy = self
        copy.baseNameBuilder = builder
        return copy
    }

    public func build(_ n: Int = 0) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .ordinal
        return "\(numberFormatter.string(from: NSNumber(value: n + 1))!) \(self.baseNameBuilder(n))" // swiftlint:disable:this force_unwrapping
    }
}
