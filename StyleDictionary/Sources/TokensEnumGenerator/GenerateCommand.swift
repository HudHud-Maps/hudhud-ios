//
//  File.swift
//  TokensEnumGenerator
//
//  Created by Patrick Kladek on 09.10.24.
//

import ArgumentParser
import Foundation
import Stencil

@main
struct GenerateCommand: ParsableCommand {
	static let configuration: CommandConfiguration = .init(commandName: "generate")

	@Option(help: "Path to the input JSON file for typography")
	var inputFile: URL?

	@Option(help: "Path to the asset catalog colors")
	var assetsPath: URL?

	@Option(help: "Type of generation (typography/colors)")
	var type: String

	@Option(help: "Template file path")
	var template: URL?

	@Option(help: "Output file path")
	var outputFile: URL

	mutating func run() throws {
		switch type {
		case "typography":
			try generateTypography()
		case "colors":
			try generateColors()
		case "all":
				try generateTypography()
			
				try generateColors()
		
		default:
			throw GenerateError.invalidType
		}
	}

	private func generateTypography() throws {
		guard let inputFile = inputFile else { throw GenerateError.missingInput }
		print("Input: \(inputFile.path)")
		guard let tokens = try readTokensJSON(at: inputFile)["ui-font-text-styles"] as? [String: Any] else {
			throw GenerateError.wrongFormat
		}

		// Extract top-level keys as enum cases
		let styles = tokens.keys.sorted().map { value in
			let key = value.split(separator: ".").map { $0.capitalized }.joined().firstlowercased
			return Style(key: key, name: value)
		}
		let context = ["styles": styles]

		// Generate Swift code using Stencil template
		let enumCode = try generateEnumCode(from: context)
		print(enumCode)

		try enumCode.write(to: outputFile, atomically: true, encoding: .utf8)
	}

	private func generateColors() throws {
		guard let assetsPath = assetsPath else { throw GenerateError.missingInput }
		let colors = try parseColorAssets(at: assetsPath)
		let context = ["colors": colors]
		let generated = try generateEnumCode(from: context)
		
		try FileManager.default.createDirectory(
			at: outputFile.deletingLastPathComponent(),
			withIntermediateDirectories: true
		)
		
		try generated.write(to: outputFile, atomically: true, encoding: .utf8)
	}
}

extension GenerateCommand {

	enum GenerateError: Error {
		case wrongFormat
		case missingInput
		case invalidType
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
		guard let customTemplate = self.template else {
			throw GenerateError.missingInput
		}
		
		let template = try String(contentsOf: customTemplate)
		let environment = Environment()
		return try environment.renderTemplate(string: template, context: context)
	}

	func parseColorAssets(at url: URL) throws -> [String: Any] {
		let fileManager = FileManager.default
		var colorDict: [String: Any] = [:]
		
		print("Attempting to read colors from: \(url.path)")
		
		guard fileManager.fileExists(atPath: url.path) else {
			print("Error: Colors directory does not exist at \(url.path)")
			throw GenerateError.missingInput
		}
		
		let contents = try fileManager.contentsOfDirectory(
			at: url,
			includingPropertiesForKeys: nil,
			options: [.skipsHiddenFiles]
		)
		
		for directory in contents {
			guard directory.hasDirectoryPath else { continue }
			let categoryName = directory.lastPathComponent
			
			let colorSets = try fileManager.contentsOfDirectory(
				at: directory,
				includingPropertiesForKeys: nil,
				options: [.skipsHiddenFiles]
			).filter { $0.pathExtension == "colorset" }
			
			print("Found \(colorSets.count) colors in \(categoryName)")
			
			for colorSet in colorSets {
				let name = colorSet.deletingPathExtension().lastPathComponent
				let contentsURL = colorSet.appendingPathComponent("Contents.json")
				
				guard fileManager.fileExists(atPath: contentsURL.path) else {
					print("Warning: Missing Contents.json for color \(name)")
					continue
				}
				
				print("Processing color: \(categoryName).\(name)")
				let data = try Data(contentsOf: contentsURL)
				
				if let colorInfo = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
					let cleanName = name
						.replacingOccurrences(of: " ", with: "")
						.replacingOccurrences(of: "\\", with: "")
						.replacingOccurrences(of: "&", with: "And")
						.replacingOccurrences(of: "(", with: "")
						.replacingOccurrences(of: ")", with: "")

					let colorName = cleanName.first?.isNumber == true ? "_\(cleanName)" : cleanName

					colorDict[categoryName] = colorDict[categoryName] as? [String: Any] ?? [:]
					var categoryColors = colorDict[categoryName] as! [String: Any]

					categoryColors[colorName] = [
						"name": name,  // Keep original name without path
						"category": categoryName,
						"key": colorName
					]
					colorDict[categoryName] = categoryColors
				}
			}
		}
		
		if colorDict.isEmpty {
			print("Warning: No colors were found in the asset catalog")
		}
		
		return colorDict
	}
}

extension StringProtocol {
	var firstlowercased: String { prefix(1).lowercased() + dropFirst() }
}

extension URL: @retroactive ExpressibleByArgument {

	/// Creates a `URL` instance from a string argument.
	///
	/// Initializes a `URL` instance using the path provided as an argument string.
	/// - Parameter argument: The string argument representing the path for the URL.
	public init?(argument: String) { self.init(fileURLWithPath: argument) }
}
