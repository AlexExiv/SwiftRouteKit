import Foundation
import SwiftParser
import SwiftSyntax

struct RouteDeclaration
{
    let controller: String
    let path: String
    let uri: String
    let singleTop: String
    let animation: String?
    let middlewares: [String]
    let file: String
}

struct GlobalMiddlewareDeclaration
{
    let type: String
    let order: Int
    let file: String
}

struct GeneratorError: Error, CustomStringConvertible
{
    let description: String
}

struct Arguments
{
    let module: String
    let runtimeImport: String
    let output: String
    let files: [String]
}

let arguments = try ParseArguments()
let result = try Scan( files: arguments.files )
try Validate( routes: result.routes )
let source = Render(
    module: arguments.module,
    runtimeImport: arguments.runtimeImport,
    routes: result.routes,
    globals: result.globals )
try source.write( toFile: arguments.output, atomically: true, encoding: .utf8 )

func ParseArguments() throws -> Arguments
{
    var module = ""
    var runtimeImport = "RouterSwiftUI"
    var output = ""
    var files = [String]()

    var index = 1
    while index < CommandLine.arguments.count
    {
        let arg = CommandLine.arguments[index]
        switch arg
        {
        case "--module":
            index += 1
            module = CommandLine.arguments[index]
        case "--runtime-import":
            index += 1
            runtimeImport = CommandLine.arguments[index]
        case "--output":
            index += 1
            output = CommandLine.arguments[index]
        default:
            files.append( arg )
        }

        index += 1
    }

    guard output.isEmpty == false else
    {        throw GeneratorError( description: "RouterSwiftUI generator: --output is required" )
    }

    return Arguments( module: module, runtimeImport: runtimeImport, output: output, files: files )
}

func Scan( files: [String] ) throws -> ( routes: [RouteDeclaration], globals: [GlobalMiddlewareDeclaration] )
{
    var routes = [RouteDeclaration]()
    var globals = [GlobalMiddlewareDeclaration]()

    for file in files
    {
        let source = try String( contentsOfFile: file, encoding: .utf8 )
        _ = Parser.parse( source: source )

        let declarations = DeclarationBlocks( in: source )
        for declaration in declarations
        {
            if let routeAttribute = declaration.attributes.first( where: { $0.name == "Route" } )
            {
                guard let path = ExtractPathType( from: declaration.inheritance ) else
                {                    throw GeneratorError( description: "\(file): @Route controller \(declaration.name) must inherit RouteController<Path, View> or RouteControllerVM<Path, VM, View>." )
                }

                let middlewares = declaration.attributes
                    .first( where: { $0.name == "UseMiddlewares" } )
                    .map { ParseTypeList( $0.arguments ) } ?? []

                routes.append( RouteDeclaration(
                    controller: declaration.name,
                    path: path,
                    uri: ParseStringArgument( "uri", in: routeAttribute.arguments ) ?? "",
                    singleTop: ParseSingleTop( routeAttribute.arguments ),
                    animation: ParseTypeArgument( "animation", in: routeAttribute.arguments ),
                    middlewares: middlewares,
                    file: file ) )
            }

            if let globalAttribute = declaration.attributes.first( where: { $0.name == "GlobalMiddleware" } )
            {
                globals.append( GlobalMiddlewareDeclaration(
                    type: declaration.name,
                    order: ParseIntArgument( "order", in: globalAttribute.arguments ) ?? 0,
                    file: file ) )
            }
        }
    }

    return ( routes, globals )
}

func Validate( routes: [RouteDeclaration] ) throws
{
    var uris = [String: String]()
    var paths = [String: String]()

    for route in routes
    {
        if route.uri.isEmpty == false
        {
            try ValidateURI( route.uri, file: route.file )
            if let existing = uris[route.uri]
            {
                throw GeneratorError( description: "\(route.file): duplicate route uri \(route.uri). Already used by \(existing)." )
            }

            uris[route.uri] = route.controller
        }

        if let existing = paths[route.path]
        {
            throw GeneratorError( description: "\(route.file): duplicate RoutePath registration \(route.path). Already used by \(existing)." )
        }

        paths[route.path] = route.controller
    }
}

func ValidateURI( _ uri: String, file: String ) throws
{
    guard uri.first == "/" else
    {        throw GeneratorError( description: "\(file): route uri must start with '/': \(uri)" )
    }

    var names = Set<String>()
    for segment in uri.split( separator: "?", maxSplits: 1 ).first?.split( separator: "/" ) ?? []
    {
        guard segment.first == ":" else { continue }

        let name = String( segment.dropFirst() )
        guard name.isEmpty == false, names.contains( name ) == false else
        {            throw GeneratorError( description: "\(file): invalid route uri pattern \(uri)" )
        }

        names.insert( name )
    }
}

func Render(
    module: String,
    runtimeImport: String,
    routes: [RouteDeclaration],
    globals: [GlobalMiddlewareDeclaration] ) -> String
{
    var lines = [String]()
    lines.append( "// Generated by RouterSwiftUIGenerator. Do not edit." )
    lines.append( "import Foundation" )
    if module != runtimeImport
    {
        lines.append( "import \(runtimeImport)" )
    }
    lines.append( "" )
    lines.append( "@MainActor" )
    lines.append( "public enum GeneratedRouteRegistry" )
    lines.append( "{" )
    lines.append( "    public static func Make() -> RouteRegistry" )
    lines.append( "    {" )
    lines.append( "        try! RouteRegistry(" )
    lines.append( "            routes: [" )

    for route in routes
    {
        let animation = route.animation.map { "\(TrimSelf( $0 )).self" } ?? "nil"
        let middlewares = route.middlewares.map { "\(TrimSelf( $0 )).self" }.joined( separator: ", " )
        lines.append( "                RouteRegistration(" )
        lines.append( "                    \(route.controller)()," )
        lines.append( "                    uri: \(StringLiteral( route.uri ))," )
        lines.append( "                    singleTop: .\(route.singleTop)," )
        lines.append( "                    animationType: \(animation)," )
        lines.append( "                    middlewareTypes: [\(middlewares)])," )
    }

    lines.append( "            ]," )
    lines.append( "            globalMiddlewares: [" )

    for middleware in globals.sorted( by: { $0.order < $1.order } )
    {
        lines.append( "                GlobalMiddlewareRegistration(\(middleware.type).self, order: \(middleware.order))," )
    }

    lines.append( "            ]" )
    lines.append( "        )" )
    lines.append( "    }" )
    lines.append( "}" )
    lines.append( "" )
    return lines.joined( separator: "\n" )
}

struct AttributeBlock
{
    let name: String
    let arguments: String
}

struct DeclarationBlock
{
    let attributes: [AttributeBlock]
    let name: String
    let inheritance: String
}

func DeclarationBlocks( in source: String ) -> [DeclarationBlock]
{
    let pattern = #"(?s)((?:\s*@\w+(?:\s*\([^@]*?\))?\s*)+)(?:\s*(?:public|internal|open|final|fileprivate|private|@MainActor)\s+)*(?:class|struct)\s+(\w+)\s*(?::\s*([^\{]+))?\{"#
    guard let regex = try? NSRegularExpression( pattern: pattern ) else { return [] }

    let range = NSRange( source.startIndex..<source.endIndex, in: source )
    return regex.matches( in: source, range: range ).compactMap {
        guard let attributesRange = Range( $0.range( at: 1 ), in: source ),
              let nameRange = Range( $0.range( at: 2 ), in: source ) else { return nil }

        let inheritanceRange = Range( $0.range( at: 3 ), in: source )
        return DeclarationBlock(
            attributes: ParseAttributes( String( source[attributesRange] ) ),
            name: String( source[nameRange] ),
            inheritance: inheritanceRange.map { String( source[$0] ) } ?? "" )
    }
}

func ParseAttributes( _ source: String ) -> [AttributeBlock]
{
    let pattern = #"@(\w+)(?:\s*\((.*?)\))?"#
    guard let regex = try? NSRegularExpression( pattern: pattern, options: [.dotMatchesLineSeparators] ) else { return [] }

    let range = NSRange( source.startIndex..<source.endIndex, in: source )
    return regex.matches( in: source, range: range ).compactMap {
        guard let nameRange = Range( $0.range( at: 1 ), in: source ) else { return nil }

        let argsRange = Range( $0.range( at: 2 ), in: source )
        return AttributeBlock(
            name: String( source[nameRange] ),
            arguments: argsRange.map { String( source[$0] ) } ?? "" )
    }
}

func ExtractPathType( from inheritance: String ) -> String?
{
    ExtractFirstGenericArgument( "RouteControllerVM", from: inheritance )
        ?? ExtractFirstGenericArgument( "RouteController", from: inheritance )
}

func ExtractFirstGenericArgument( _ type: String, from source: String ) -> String?
{
    guard let range = source.range( of: "\(type)<" ) else { return nil }

    var depth = 0
    var value = ""
    var started = false

    for character in source[range.upperBound...]
    {
        if character == "<"
        {
            depth += 1
            value.append( character )
            started = true
            continue
        }

        if character == ">"
        {
            if depth == 0
            {                break
            }

            depth -= 1
            value.append( character )
            continue
        }

        if character == ",", depth == 0
        {
            break
        }

        started = true
        value.append( character )
    }

    let trimmed = value.trimmingCharacters( in: .whitespacesAndNewlines )
    return started && trimmed.isEmpty == false ? trimmed : nil
}

func ParseStringArgument( _ name: String, in source: String ) -> String?
{
    let pattern = #"\#(name)\s*:\s*"([^"]*)""#
    guard let regex = try? NSRegularExpression( pattern: pattern ),
          let match = regex.firstMatch( in: source, range: NSRange( source.startIndex..<source.endIndex, in: source ) ),
          let range = Range( match.range( at: 1 ), in: source ) else { return nil }

    return String( source[range] )
}

func ParseIntArgument( _ name: String, in source: String ) -> Int?
{
    let pattern = #"\#(name)\s*:\s*(-?\d+)"#
    guard let regex = try? NSRegularExpression( pattern: pattern ),
          let match = regex.firstMatch( in: source, range: NSRange( source.startIndex..<source.endIndex, in: source ) ),
          let range = Range( match.range( at: 1 ), in: source ) else { return nil }

    return Int( source[range] )
}

func ParseSingleTop( _ source: String ) -> String
{
    let pattern = #"singleTop\s*:\s*\.?(\w+)"#
    guard let regex = try? NSRegularExpression( pattern: pattern ),
          let match = regex.firstMatch( in: source, range: NSRange( source.startIndex..<source.endIndex, in: source ) ),
          let range = Range( match.range( at: 1 ), in: source ) else { return "none" }

    let value = String( source[range] )
    return value.prefix( 1 ).lowercased() + value.dropFirst()
}

func ParseTypeArgument( _ name: String, in source: String ) -> String?
{
    let pattern = #"\#(name)\s*:\s*([\w\.]+)\.self"#
    guard let regex = try? NSRegularExpression( pattern: pattern ),
          let match = regex.firstMatch( in: source, range: NSRange( source.startIndex..<source.endIndex, in: source ) ),
          let range = Range( match.range( at: 1 ), in: source ) else { return nil }

    let value = String( source[range] )
    return value == "Never" ? nil : value
}

func ParseTypeList( _ source: String ) -> [String]
{
    source
        .split( separator: "," )
        .map { $0.trimmingCharacters( in: .whitespacesAndNewlines ) }
        .filter { $0.isEmpty == false }
        .map( TrimSelf )
}

func TrimSelf( _ value: String ) -> String
{
    value.replacingOccurrences( of: ".self", with: "" )
}

func StringLiteral( _ value: String ) -> String
{
    "\"" + value
        .replacingOccurrences( of: "\\", with: "\\\\" )
        .replacingOccurrences( of: "\"", with: "\\\"" ) + "\""
}
