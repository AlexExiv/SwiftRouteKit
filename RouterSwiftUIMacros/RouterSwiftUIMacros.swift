import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct RouteMacro: ExtensionMacro, MemberMacro
{
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext) throws -> [DeclSyntax]
    {
        guard let route = RouteControllerInfo( declaration: declaration ) else { return [] }

        if let viewModelType = route.viewModelType
        {
            var members = [DeclSyntax]()
            if route.hasOnCreateViewModel == false
            {
                members.append(
                    """
                    public override func OnCreateViewModel( path: \(raw: route.pathType) ) -> \(raw: viewModelType)
                    {
                        \(raw: viewModelType)()
                    }
                    """ )
            }

            if route.hasOnCreateViewWithViewModel == false
            {
                members.append(
                    """
                    public override func OnCreateView( path: \(raw: route.pathType), viewModel: \(raw: viewModelType) ) -> \(raw: route.viewType)
                    {
                        \(raw: route.viewType)( viewModel: viewModel )
                    }
                    """ )
            }

            return members
        }

        guard route.hasOnCreateView == false else { return [] }

        return [
            """
            public override func OnCreateView( path: \(raw: route.pathType) ) -> \(raw: route.viewType)
            {
                \(raw: route.viewType)()
            }
            """
        ]
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext) throws -> [ExtensionDeclSyntax]
    {
        []
    }
}

private struct RouteControllerInfo
{
    let pathType: String
    let viewModelType: String?
    let viewType: String
    let hasOnCreateView: Bool
    let hasOnCreateViewModel: Bool
    let hasOnCreateViewWithViewModel: Bool

    init?( declaration: some DeclGroupSyntax )
    {
        let source = declaration.description
        if let arguments = Self.GenericArguments( of: "RouteControllerVM", in: source ), arguments.count >= 3
        {
            pathType = arguments[0]
            viewModelType = arguments[1]
            viewType = arguments[2]
        }
        else if let arguments = Self.GenericArguments( of: "RouteController", in: source ), arguments.count >= 2
        {
            pathType = arguments[0]
            viewModelType = nil
            viewType = arguments[1]
        }
        else
        {
            return nil
        }

        let methods = Self.Methods( in: declaration )
        hasOnCreateView = methods.contains {
            $0.name == "OnCreateView" && $0.parameterLabels == ["path"]
        }
        hasOnCreateViewModel = methods.contains {
            $0.name == "OnCreateViewModel" && $0.parameterLabels == ["path"]
        }
        hasOnCreateViewWithViewModel = methods.contains {
            $0.name == "OnCreateView" && $0.parameterLabels == ["path", "viewModel"]
        }
    }

    private static func Methods( in declaration: some DeclGroupSyntax ) -> [( name: String, parameterLabels: [String] )]
    {
        declaration.memberBlock.members.compactMap {
            guard let function = $0.decl.as( FunctionDeclSyntax.self ) else { return nil }

            return (
                name: function.name.text,
                parameterLabels: function.signature.parameterClause.parameters.map { $0.firstName.text }
            )
        }
    }

    private static func GenericArguments( of type: String, in source: String ) -> [String]?
    {
        guard let range = source.range( of: "\(type)<" ) else { return nil }

        var arguments = [String]()
        var current = ""
        var depth = 0

        for character in source[range.upperBound...]
        {
            switch character
            {
            case "<":
                depth += 1
                current.append( character )
            case ">":
                if depth == 0
                {
                    Append( current, to: &arguments )
                    return arguments
                }

                depth -= 1
                current.append( character )
            case "," where depth == 0:
                Append( current, to: &arguments )
                current.removeAll()
            default:
                current.append( character )
            }
        }

        return nil
    }

    private static func Append( _ value: String, to arguments: inout [String] )
    {
        let argument = value.trimmingCharacters( in: .whitespacesAndNewlines )
        if argument.isEmpty == false
        {
            arguments.append( argument )
        }
    }
}

public struct UseMiddlewaresMacro: ExtensionMacro
{
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext) throws -> [ExtensionDeclSyntax]
    {
        []
    }
}

public struct GlobalMiddlewareMacro: ExtensionMacro
{
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext) throws -> [ExtensionDeclSyntax]
    {
        []
    }
}

@main
struct RouterSwiftUIMacroPlugin: CompilerPlugin
{
    let providingMacros: [Macro.Type] = [
        RouteMacro.self,
        UseMiddlewaresMacro.self,
        GlobalMiddlewareMacro.self
    ]
}
