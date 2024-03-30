//
//  Averageable.swift
//  HudHud
//
//  Created by Patrick Kladek on 27.03.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

// MARK: - Averageable

protocol Averageable: NSObject {
	static var zero: Self { get }
	func average(_ newElement: Averageable, entries: Int) -> Self
}

extension Averageable {

	func average(_ newElement: Averageable, entries: Int) -> Self {
		let newElementMirror = Mirror(reflecting: newElement)
		let mirror = Mirror(reflecting: self)

		let copy = self.copy() as! Self // swiftlint:disable:this force_cast
		for child in mirror.children {
			for newElementChild in newElementMirror.children {
				guard let label = child.label else { continue }
				guard newElementChild.label == label else { continue }

				guard let newValue = newElementChild.value as? Double else { continue }
				guard let value = child.value as? Double else { continue }

				copy.setValue(value + (newValue / Double(entries)), forKeyPath: label)
			}
		}
		return copy
	}
}

extension Array where Element: Averageable {

	func average() -> Element? {
		let average = self.reduce(Element.zero) { partialResult, container in
			return partialResult.average(container, entries: self.count)
		}

		return average
	}
}
