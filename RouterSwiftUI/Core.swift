import Foundation
import SwiftUI

public protocol RoutePath: Hashable
{
}

public protocol EmptyParamsPath: RoutePath
{
    init()
}

public struct AnyRoutePath: Hashable
{
    public let base: any RoutePath
    public let typeName: String

    public init( _ base: any RoutePath )
    {
        self.base = base
        self.typeName = String( reflecting: Swift.type( of: base ) )
    }

    public func Typed<Path: RoutePath>( _ type: Path.Type = Path.self ) -> Path?
    {
        base as? Path
    }

    public func IsSameType( as path: AnyRoutePath ) -> Bool
    {
        typeName == path.typeName
    }

    public static func == ( lhs: AnyRoutePath, rhs: AnyRoutePath ) -> Bool
    {
        AnyHashable( lhs.base ) == AnyHashable( rhs.base )
    }

    public func hash( into hasher: inout Hasher )
    {
        AnyHashable( base ).hash( into: &hasher )
    }
}

public enum RouteSingleTop: String
{
    case none
    case `class`
    case equal
}

public enum RouteTabUnique: String
{
    case none
    case `class`
    case equal
}

public enum RouterError: Error, CustomStringConvertible
{
    case routeNotFound( AnyRoutePath )
    case urlNotFound( String )
    case pathTypeMismatch( expected: Any.Type, actual: Any.Type )
    case urlConversionUnsupported( Any.Type, String )
    case duplicateURI( String )
    case duplicatePath( String )
    case invalidURI( String )
    case missingRouteEntry

    public var description: String
    {
        switch self
        {
        case .routeNotFound( let path ):
            return "Route has not been found for path \(path.typeName)"
        case .urlNotFound( let url ):
            return "Route has not been found for url \(url)"
        case .pathTypeMismatch( let expected, let actual ):
            return "Expected route path \(expected), got \(actual)"
        case .urlConversionUnsupported( let type, let uri ):
            return "Route controller for \(type) could not convert uri \(uri)"
        case .duplicateURI( let uri ):
            return "Duplicate route uri \(uri)"
        case .duplicatePath( let path ):
            return "Duplicate route path registration \(path)"
        case .invalidURI( let uri ):
            return "Invalid route uri \(uri)"
        case .missingRouteEntry:
            return "Router route entry is missing from SwiftUI environment"
        }
    }
}

public protocol RouterView: View
{
}

public protocol RouterDialogView: RouterView
{
}

public protocol RouterFullScreenView: RouterView
{
}

public protocol RouterBottomSheetView: RouterView
{
    static var routerPresentationDetents: Set<PresentationDetent> { get }
}

public extension RouterBottomSheetView
{
    static var routerPresentationDetents: Set<PresentationDetent>
    {
        [.medium, .large]
    }
}

public protocol RouterTabsView: RouterView
{
}

public enum RoutePresentationStyle
{
    case push
    case dialog
    case fullScreen
    case bottomSheet( Set<PresentationDetent> )

    public var isNoStackPresentation: Bool
    {
        switch self
        {
        case .push:
            return false
        case .dialog, .fullScreen, .bottomSheet:
            return true
        }
    }
}

public enum RouteContainerStyle
{
    case screen
    case tabs
}

@MainActor
public protocol AnimationController: AnyObject
{
    init()

    func Transaction( for command: RouterCommand ) -> Transaction?
}

public extension AnimationController
{
    func Transaction( for command: RouterCommand ) -> Transaction?
    {
        nil
    }
}

public struct RouteParams: Hashable
{
    public var hasResult: Bool
    {
        resultBinding != nil
    }

    public let path: AnyRoutePath
    public let isReplace: Bool
    public let tabIndex: Int?

    let resultBinding: RouteResultBinding?

    public init( path: AnyRoutePath, isReplace: Bool = false, tabIndex: Int? = nil )
    {
        self.init( path: path, isReplace: isReplace, tabIndex: tabIndex, resultBinding: nil )
    }

    public init<Path: RoutePath>( path: Path, isReplace: Bool = false, tabIndex: Int? = nil )
    {
        self.init( path: AnyRoutePath( path ), isReplace: isReplace, tabIndex: tabIndex, resultBinding: nil )
    }

    init( path: AnyRoutePath, isReplace: Bool = false, tabIndex: Int? = nil, resultBinding: RouteResultBinding? )
    {
        self.path = path
        self.isReplace = isReplace
        self.tabIndex = tabIndex
        self.resultBinding = resultBinding
    }
}
