//
//  TokensEnumGeneratorPlugin.swift
//  StyleDictionary
//
//  Created by Patrick Kladek on 09.10.24.
//

import Foundation
import PackagePlugin

// MARK: - TokensEnumGeneratorPlugin

@main
struct TokensEnumGeneratorPlugin {}

// MARK: - BuildToolPlugin

extension TokensEnumGeneratorPlugin: BuildToolPlugin {

    func createBuildCommands(context: PluginContext, target _: Target) throws -> [Command] {
        // Assuming `tokens.json` is passed as an argument
        let inputPath = context.package.directoryURL.appending(path: "Supporting Files/tokens.json")

        // Define the command to generate the enums using the template
        return try [
            .buildCommand(displayName: "Generating Enums from tokens.json",
                          executable: context.tool(named: "TokensEnumGenerator").url,
                          arguments: [inputPath.absoluteString])
        ]
    }
}

#if canImport(XcodeProjectPlugin)
    import XcodeProjectPlugin

    extension TokensEnumGeneratorPlugin: XcodeBuildToolPlugin {

        func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
            let inputPath = context.xcodeProject.directoryURL
                .appending(path: target.displayName)
                .appending(path: "Supporting Files")
                .appending(path: "typography-design-tokens.json")
            let templatePath = context.xcodeProject.directoryURL
                .appending(path: "StyleDictionary")
                .appending(path: "customTemplate.stencil")
            let output = context.pluginWorkDirectoryURL
                .appending(path: "GeneratedSources")
                .appending(path: "TextStyles.swift")

            return try [
                .buildCommand(displayName: "Generate",
                              executable: context.tool(named: "TokensEnumGenerator").url,
                              arguments: [
                                  "--input-file", inputPath.path, "--template", templatePath.path, "--output-file", output.path
                              ],
                              environment: [:],
                              inputFiles: [inputPath],
                              outputFiles: [output])
            ]
        }
    }
#endif
