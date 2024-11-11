//
//  GenerateCommand.swift
//  TokensEnumGenerator
//
//  Created by Patrick Kladek on 09.10.24.
//

import ArgumentParser
import Foundation
import Stencil

// MARK: - GenerateCommand

@main
struct GenerateCommand: ParsableCommand {

    // MARK: Static Properties

    static let configuration: CommandConfiguration = .init(commandName: "generate")

    // MARK: Properties

    @Option(help: "path to tokens.json file")
    var inputFile: URL

    @Option(help: "path to custom stencil template")
    var template: URL?

    @Option(help: "Output directory where the generated files are written.")
    var outputFile: URL = .init(fileURLWithPath: FileManager.default.currentDirectoryPath)

    // MARK: Functions

    mutating func run() throws {
        print("Input: \(self.inputFile.path)")
        guard let tokens = try readTokensJSON(at: self.inputFile)["ui-font-text-styles"] as? [String: Any] else {
            throw GenerateError.wrongFormat
        }

        // Extract top-level keys as enum cases
        let styles = tokens.keys.sorted().map { value in
            let key = value.split(separator: ".").map(\.capitalized).joined().firstlowercased
            return Style(key: key, name: value)
        }
        let context = ["styles": styles]

        // Generate Swift code using Stencil template
        let enumCode = try generateEnumCode(from: context)
        print(enumCode)

        try enumCode.write(to: self.outputFile, atomically: true, encoding: .utf8)
    }
}

extension GenerateCommand {

    enum GenerateError: Error {
        case wrongFormat
    }

    struct Style {
        let key: String
        let name: String
    }

    // Helper function to read JSON data from file
    func readTokensJSON(at url: URL) throws -> [String: Any] {
        let data = try Data(contentsOf: url)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "Invalid JSON format", code: 1, userInfo: nil)
        }
        return json
    }

    // Helper function to generate Swift code from a template and context
    func generateEnumCode(from context: [String: Any]) throws -> String {
        if let customTemplate = self.template {
            let template = try String(contentsOf: customTemplate)
            let environment = Environment(loader: FileSystemLoader(paths: ["./Resources"]))
            return try environment.renderTemplate(string: template, context: context)
        }

        let templatePath = "Resources/template.stencil" // Adjust as needed
        let template = try String(contentsOfFile: templatePath)
        let environment = Environment(loader: FileSystemLoader(paths: ["./Resources"]))
        return try environment.renderTemplate(string: template, context: context)
    }
}

extension StringProtocol {
    var firstlowercased: String { prefix(1).lowercased() + dropFirst() }
}

// MARK: - URL + ExpressibleByArgument

extension URL: @retroactive ExpressibleByArgument {

    /// Creates a `URL` instance from a string argument.
    ///
    /// Initializes a `URL` instance using the path provided as an argument string.
    /// - Parameter argument: The string argument representing the path for the URL.
    public init?(argument: String) { self.init(fileURLWithPath: argument) }
}
