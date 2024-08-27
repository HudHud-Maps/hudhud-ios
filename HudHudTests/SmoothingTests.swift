//
//  SmoothingTests.swift
//  HudHudTests
//
//  Created by Patrick Kladek on 27.03.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

@testable import HudHud
import XCTest

final class SmoothingTests: XCTestCase {

    // MARK: Nested Types

    struct SingleContainer<T> {
        let value: T
    }

    @objcMembers
    class MultiContainer: NSObject, Averageable {

        // MARK: Static Computed Properties

        static var zero: Self {
            MultiContainer(first: 0, second: 0) as! Self // swiftlint:disable:this force_cast
        }

        // MARK: Overridden Properties

        override var description: String {
            return String(format: "first: %.1f, second: %.1f", self.first, self.second)
        }

        // MARK: Properties

        var first: Double
        var second: Double

        // MARK: Lifecycle

        init(first: Double, second: Double) {
            self.first = first
            self.second = second
        }
    }

    // MARK: Functions

    // MARK: - SmoothingTests

    func testSimpleContainerAverage() throws {
        let measurments: [SingleContainer<Double>] = [
            SingleContainer(value: 2),
            SingleContainer(value: 4),
            SingleContainer(value: 6),
            SingleContainer(value: 8)
        ]

        let average = measurments.reduce(SingleContainer(value: 0)) { partialResult, container in
            return SingleContainer(value: partialResult.value + (container.value / Double(measurments.count)))
        }
        XCTAssertEqual(average.value, 5)
    }

    func testMultiContainerAverage() throws {
        let measurments: [MultiContainer] = [
            MultiContainer(first: 2, second: 4),
            MultiContainer(first: 4, second: 6),
            MultiContainer(first: 6, second: 8),
            MultiContainer(first: 8, second: 10)
        ]

        let average = measurments.reduce(MultiContainer.zero) { partialResult, container in
            return partialResult.average(container, entries: measurments.count)
        }

        XCTAssertEqual(average.first, 5)
        XCTAssertEqual(average.second, 7)
    }

    func testDynamicAverage() throws {
        let measurments: [MultiContainer] = [
            MultiContainer(first: 2, second: 4),
            MultiContainer(first: 4, second: 6),
            MultiContainer(first: 6, second: 8),
            MultiContainer(first: 8, second: 10)
        ]

        let average = measurments.average()

        XCTAssertEqual(average?.first, 5)
        XCTAssertEqual(average?.second, 7)
    }

    func testDynamicAveragePerformance() throws {
        let count = 120
        let range = 360.0

        let measurments: [MultiContainer] = (0 ..< count).map { _ in
            MultiContainer(first: .random(in: 0 ..< range), second: .random(in: 0 ..< range))
        }

        // On Mac Mini M1 takes 1ms
        self.measure {
            _ = measurments.average()
        }
    }
}
