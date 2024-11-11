//
//  TokensEnumGeneratorTests.swift
//  TokensEnumGenerator
//
//  Created by Patrick Kladek on 09.10.24.
//

import Stencil
import XCTest
@testable import TokensEnumGenerator

final class TokensEnumGeneratorTests: XCTestCase {

    func testReadTokensJSON() throws {
        // Prepare a temporary JSON file
        let jsonContent = """
        {
        	"colorPrimary": "#FF5733",
        	"colorSecondary": "#33CFFF",
        	"fontSizeLarge": 18
        }
        """
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("tokens.json")
        try jsonContent.write(to: tempURL, atomically: true, encoding: .utf8)

        // Read the JSON file
        let tokens = try readTokensJSON(at: tempURL.path)

        // Assertions
        XCTAssertEqual(tokens.count, 3)
        XCTAssertEqual(tokens["colorPrimary"] as? String, "#FF5733")
        XCTAssertEqual(tokens["colorSecondary"] as? String, "#33CFFF")
        XCTAssertEqual(tokens["fontSizeLarge"] as? Int, 18)

        // Clean up
        try FileManager.default.removeItem(at: tempURL)
    }

    func testGenerateEnumCode() throws {
        // Prepare the context
        let context = [
            "enumCases": [
                "heading.xxLarge",
                "heading.xLarge",
                "heading.large",
                "heading.medium",
                "heading.xSmall",
                "label.large",
                "label.medium",
                "label.small",
                "label.smallExtraBold",
                "label.xSmall",
                "label.xxSmall",
                "paragraph.large",
                "paragraph.medium",
                "paragraph.small",
                "paragraph.xSmall"]
        ]

        // Define the template inline for testing
        let template = """
        enum TokenKeys {
        {% for case in enumCases %}
        	case {{ case }}
        {% endfor %}
        }
        """

        // Generate the enum code
        let environment = Environment(loader: FileSystemLoader(paths: ["./Resources"]))
        let output = try environment.renderTemplate(string: template, context: context)

        // Expected output
        let expectedOutput = """
        enum TokenKeys {

        	case heading.xxLarge

        	case heading.xLarge

        	case heading.large

        	case heading.medium

        	case heading.xSmall

        	case label.large

        	case label.medium

        	case label.small

        	case label.smallExtraBold

        	case label.xSmall

        	case label.xxSmall

        	case paragraph.large

        	case paragraph.medium

        	case paragraph.small

        	case paragraph.xSmall

        }
        """

        print(output.trimmingCharacters(in: .whitespacesAndNewlines))

        // Assertions
        XCTAssertEqual(output.trimmingCharacters(in: .whitespacesAndNewlines), expectedOutput.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
