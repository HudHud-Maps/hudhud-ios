//
//  XCTestCase+Additions.swift
//  HudHud
//
//  Created by Patrick Kladek on 30.09.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import XCTest

extension XCTestCase {

    func takeScreenshot(of element: XCUIElement, name: String) {
        // Give time to finish loading elements
        sleep(2)

        let attachment = XCTAttachment(screenshot: element.screenshot())
        attachment.name = UIDevice.current.simulatorModel() + " - " + name
        attachment.lifetime = .keepAlways
        self.add(attachment)
    }
}

extension XCUIElementQuery {

    subscript(begins with: String) -> XCUIElement {
        let predicate = NSPredicate(format: "label BEGINSWITH[cd] '\(with)'")
        return self.element(matching: predicate)
    }

    subscript(contains text: String) -> XCUIElement {
        let predicate = NSPredicate(format: "label CONTAINS[cd] '\(text)'")
        return self.element(matching: predicate)
    }
}

extension XCUIElement {

    func waitForExists(timeout: TimeInterval = 20, file: StaticString = #file, line: UInt = #line) {
        guard self.waitForExistence(timeout: timeout) == true else {
            XCTFail("\(self) never appeared...", file: file, line: line)
            return
        }
    }

    @discardableResult
    func optionallyWaitForAndTap(timeout: TimeInterval = 10, file _: StaticString = #file, line _: UInt = #line) -> Bool {
        guard self.waitForExistence(timeout: timeout) == true else { return false }
        self.tap()
        return true
    }

    @discardableResult
    func optionallyTap(file _: StaticString = #file, line _: UInt = #line) -> Bool {
        guard self.exists else { return false }

        self.tap()
        return true
    }
}

extension UIDevice {

    func simulatorModel() -> String {
        let pattern = "^Clone \\d+ of "
        return self.name.removing(pattern: pattern)
    }
}

extension String {

    func removing(pattern: String) -> String {
        // Use regular expression to remove the dynamic "Clone X of" part
        let regex = try! NSRegularExpression(pattern: pattern) // swiftlint:disable:this force_try
        let range = NSRange(self.startIndex ..< self.endIndex, in: self)
        let updatedString = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "")
        return updatedString
    }

    func firstMatch(pattern: String) -> String? {
        let regex = try! NSRegularExpression(pattern: pattern, options: []) // swiftlint:disable:this force_try
        let range = NSRange(location: 0, length: self.utf16.count)
        if let match = regex.firstMatch(in: self, options: [], range: range) {
            if let numberRange = Range(match.range, in: self) {
                return String(self[numberRange])
            }
        }
        return nil
    }
}
