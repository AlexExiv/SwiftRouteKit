import PackagePlugin
import Foundation

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin
#endif

@main
struct RouterSwiftUIGeneratorPlugin: BuildToolPlugin
{
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command]
    {
        let swiftFiles = SwiftPackageFiles( target: target )
        
        return try MakeBuildCommands(
            targetName: target.name,
            swiftFiles: swiftFiles,
            output: context.pluginWorkDirectory.appending( "GeneratedRouteRegistry.swift" ),
            tool: context.tool( named: "RouterSwiftUIGenerator" )
        )
    }
    
    private func MakeBuildCommands(
        targetName: String,
        swiftFiles: [Path],
        output: Path,
        tool: PluginContext.Tool
    ) throws -> [Command]
    {
        guard swiftFiles.isEmpty == false else { return [] }

        return [
            .buildCommand(
                displayName: "Generate RouterSwiftUI registry for \(targetName)",
                executable: tool.path,
                arguments: [
                    "--module",
                    targetName,
                    "--runtime-import",
                    "RouterSwiftUI",
                    "--output",
                    output.string
                ] + swiftFiles.map { $0.string },
                inputFiles: swiftFiles,
                outputFiles: [output])
        ]
    }
    
    private func SwiftPackageFiles( target: Target ) -> [Path]
    {
        if let target = target as? SourceModuleTarget
        {
            return target.sourceFiles( withSuffix: "swift" ).map { $0.path }
        }

        return SwiftFiles( target.directory )
    }
    
    private func SwiftFiles( _ files: FileList ) -> [Path]
    {
        files
            .map { $0.path }
            .filter { $0.extension == "swift" }
            .filter { $0.lastComponent != "GeneratedRouteRegistry.swift" }
            .sorted { $0.string < $1.string }
    }
    
    private func SwiftFiles( _ root: Path ) -> [Path]
    {
        guard let enumerator = FileManager.default.enumerator( atPath: root.string ) else { return [] }
        
        return enumerator
            .compactMap { $0 as? String }
            .filter { $0.hasSuffix( ".swift" ) }
            .filter { $0.hasSuffix( "GeneratedRouteRegistry.swift" ) == false }
            .map { root.appending( subpath: $0 ) }
            .sorted { $0.string < $1.string }
    }
}

#if canImport(XcodeProjectPlugin)
extension RouterSwiftUIGeneratorPlugin: XcodeBuildToolPlugin
{
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command]
    {
        try MakeBuildCommands(
            targetName: target.displayName,
            swiftFiles: SwiftFiles( target.inputFiles ),
            output: context.pluginWorkDirectory.appending( "GeneratedRouteRegistry.swift" ),
            tool: context.tool( named: "RouterSwiftUIGenerator" )
        )
    }
}
#endif
