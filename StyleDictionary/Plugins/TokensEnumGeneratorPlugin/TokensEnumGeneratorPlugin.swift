import Foundation
import PackagePlugin

@main
struct TokensEnumGeneratorPlugin {
    private func createOutputDirectory(at url: URL) throws {
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
    }
}

// Regular SPM plugin
extension TokensEnumGeneratorPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        // use project's GeneratedSources directory (going up from package directory)
        let outputDir = context.package.directory
            .removingLastComponent()
            .appending("GeneratedSources")
        try createOutputDirectory(at: URL(fileURLWithPath: outputDir.string))
        
        let typographyPath = target.directory
            .appending("SupportingFiles")
            .appending("typography-design-tokens.json")
        
        let colorsPath = target.directory
            .appending("SupportingFiles")
            .appending("Assets.xcassets")
            .appending("Colors")
            
        let typographyTemplate = context.package.directory
            .appending("typography.stencil")
            
        let colorsTemplate = context.package.directory
            .appending("colors.stencil")

        return [
            .buildCommand(
                displayName: "Generating Typography",
                executable: try context.tool(named: "TokensEnumGenerator").path,
                arguments: [
                    "--input-file", typographyPath.string,
                    "--template", typographyTemplate.string,
                    "--output-file", outputDir.appending("FontStyles.swift").string,
                    "--type", "typography"
                ],
                environment: [:],
                inputFiles: [typographyPath, typographyTemplate],
                outputFiles: [outputDir.appending("FontStyles.swift")]
            ),
            .buildCommand(
                displayName: "Generating Colors",
                executable: try context.tool(named: "TokensEnumGenerator").path,
                arguments: [
                    "--assets-path", colorsPath.string,
                    "--template", colorsTemplate.string,
                    "--output-file", outputDir.appending("Colors.swift").string,
                    "--type", "colors"
                ],
                environment: [:],
                inputFiles: [colorsPath, colorsTemplate],
                outputFiles: [outputDir.appending("Colors.swift")]
            )
        ]
    }
}

// Xcode plugin
#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension TokensEnumGeneratorPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        // use project's GeneratedSources directory
        let outputDir = context.xcodeProject.directoryURL
            .appending(path: "GeneratedSources")
        try createOutputDirectory(at: outputDir)
        
        let typographyTemplate = context.xcodeProject.directoryURL
            .appending(path: "StyleDictionary")
            .appending(path: "typography.stencil")
            
        let colorsTemplate = context.xcodeProject.directoryURL
            .appending(path: "StyleDictionary")
            .appending(path: "colors.stencil")
        
        let typographyInputPath = context.xcodeProject.directoryURL
            .appending(path: "HudHud")
            .appending(path: "SupportingFiles")
            .appending(path: "typography-design-tokens.json")
            
        let assetsPath = context.xcodeProject.directoryURL
            .appending(path: target.displayName)
            .appending(path: "SupportingFiles")
            .appending(path: "Assets.xcassets")
            .appending(path: "Colors")
        
        return [
            .buildCommand(
                displayName: "Generate Typography",
                executable: try context.tool(named: "TokensEnumGenerator").url,
                arguments: [
                    "--input-file", typographyInputPath.path,
                    "--template", typographyTemplate.path,
                    "--output-file", outputDir.appending(path: "FontStyles.swift").path,
                    "--type", "typography"
                ],
                environment: [:],
                inputFiles: [typographyInputPath, typographyTemplate],
                outputFiles: [outputDir.appending(path: "FontStyles.swift")]
            ),
            .buildCommand(
                displayName: "Generate Colors",
                executable: try context.tool(named: "TokensEnumGenerator").url,
                arguments: [
                    "--assets-path", assetsPath.path,
                    "--template", colorsTemplate.path,
                    "--output-file", outputDir.appending(path: "Colors.swift").path,
                    "--type", "colors"
                ],
                environment: [:],
                inputFiles: [assetsPath, colorsTemplate],
                outputFiles: [outputDir.appending(path: "Colors.swift")]
            )
        ]
    }
}
#endif
