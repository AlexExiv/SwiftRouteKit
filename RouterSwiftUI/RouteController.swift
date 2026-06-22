import Foundation
import SwiftUI

@MainActor
public protocol AnyRouteController: AnyObject
{
    var pathType: Any.Type { get }
    var pathTypeName: String { get }
    var uri: String? { get }
    var singleTop: RouteSingleTop { get }
    var presentationStyle: RoutePresentationStyle { get }
    var containerStyle: RouteContainerStyle { get }
    var localMiddlewares: [any MiddlewareController] { get }

    func Configure( uri: String?, singleTop: RouteSingleTop, animationFactory: (@MainActor () -> (any AnimationController )?)?, middlewareFactories: [@MainActor () -> any MiddlewareController] )

    func CanHandle( path: AnyRoutePath ) -> Bool
    func Path( from match: RouteURLMatch ) throws -> AnyRoutePath
    func MakeEntry( path: AnyRoutePath, router: any Router, resultBinding: RouteResultBinding? ) throws -> RouteEntry
    func MakeView( entry: RouteEntry ) throws -> AnyView

    func OnBeforeRoute( router: any Router, current: AnyRoutePath, next: RouteParams ) -> Bool
    func OnRoute( router: any Router, previous: AnyRoutePath?, next: RouteParams ) -> Bool
    func OnClose( router: any Router, current: AnyRoutePath, previous: AnyRoutePath? ) -> Bool
    func IsPartOfChain( path: AnyRoutePath ) -> Bool
}

@MainActor
open class RouteController<Path: RoutePath, V: RouterView>: AnyRouteController
{
    public let pathType: Any.Type = Path.self
    public let pathTypeName: String = String( reflecting: Path.self )

    public private( set ) var uri: String?
    public private( set ) var singleTop: RouteSingleTop = .none
    public private( set ) var localMiddlewares: [any MiddlewareController] = []

    private var animationFactory: ( @MainActor () -> ( any AnimationController )? )?
    private var chainPathTypeNames = Set<String>()

    public required init()
    {
    }

    public var presentationStyle: RoutePresentationStyle
    {
        if let type = V.self as? any RouterBottomSheetView.Type
        {
            return .bottomSheet( type.routerPresentationDetents )
        }

        if V.self is any RouterDialogView.Type
        {
            return .dialog
        }

        if V.self is any RouterFullScreenView.Type
        {
            return .fullScreen
        }

        return .push
    }

    public var containerStyle: RouteContainerStyle
    {
        if V.self is any RouterTabsView.Type
        {
            return .tabs
        }

        return .screen
    }

    public final func Configure( uri: String?, singleTop: RouteSingleTop, animationFactory: ( @MainActor () -> ( any AnimationController )? )?, middlewareFactories: [@MainActor () -> any MiddlewareController] )
    {
        self.uri = uri?.isEmpty == true ? nil : uri
        self.singleTop = singleTop
        self.animationFactory = animationFactory
        self.localMiddlewares = middlewareFactories.map { $0() }
    }

    public func CanHandle( path: AnyRoutePath ) -> Bool
    {
        path.Typed( Path.self ) != nil
    }

    public func Path( from match: RouteURLMatch ) throws -> AnyRoutePath
    {
        guard let path = Convert( path: match.parameters, query: match.query ) else
        {
            throw RouterError.urlConversionUnsupported( Path.self, uri ?? "" )
        }

        return AnyRoutePath( path )
    }

    public final func MakeEntry( path: AnyRoutePath, router: any Router, resultBinding: RouteResultBinding? ) throws -> RouteEntry
    {
        guard let path = path.Typed( Path.self ) else
        {
            throw RouterError.pathTypeMismatch( expected: Path.self, actual: Swift.type( of: path.base ) )
        }

        let entry = RouteEntry( path: AnyRoutePath( path ), controller: self, presentationStyle: presentationStyle, containerStyle: containerStyle, router: router, resultBinding: resultBinding )
        Prepare( entry: entry, path: path, router: router )
        
        return entry
    }

    public final func MakeView( entry: RouteEntry ) throws -> AnyView
    {
        guard let path = entry.path.Typed( Path.self ) else
        {
            throw RouterError.pathTypeMismatch( expected: Path.self, actual: Swift.type( of: entry.path.base ) )
        }

        return AnyView( MakeRouterView( path: path, entry: entry ) )
    }

    open func OnCreateView( path: Path ) -> V
    {
        preconditionFailure( "OnCreateView(path:) must be implemented" )
    }

    open func Convert( path: [String: String], query: [String: String] ) -> Path?
    {
        guard let type = Path.self as? any EmptyParamsPath.Type else { return nil }

        return type.init() as? Path
    }

    open func MakeRouterView( path: Path, entry: RouteEntry ) -> V
    {
        OnCreateView( path: path )
    }

    open func Prepare( entry: RouteEntry, path: Path, router: any Router )
    {
    }

    open func OnBeforeRoute( router: any Router, current: Path, next: RouteParams ) -> Bool
    {
        false
    }

    open func OnRouteTo( router: any Router, previous: AnyRoutePath?, next: RouteParams ) -> Bool
    {
        false
    }

    open func OnClose( router: any Router, current: Path, previous: AnyRoutePath? ) -> Bool
    {
        false
    }

    public func OnBeforeRoute( router: any Router, current: AnyRoutePath, next: RouteParams ) -> Bool
    {
        guard let path = current.Typed( Path.self ) else { return false }

        return OnBeforeRoute( router: router, current: path, next: next )
    }

    public func OnRoute( router: any Router, previous: AnyRoutePath?, next: RouteParams ) -> Bool
    {
        OnRouteTo( router: router, previous: previous, next: next )
    }

    public func OnClose( router: any Router, current: AnyRoutePath, previous: AnyRoutePath? ) -> Bool
    {
        guard let path = current.Typed( Path.self ) else { return false }

        return OnClose( router: router, current: path, previous: previous )
    }

    open func IsPartOfChain( path: AnyRoutePath ) -> Bool
    {
        chainPathTypeNames.contains( path.typeName )
    }

    public func SetChainPaths( _ pathTypes: [any RoutePath.Type] )
    {
        chainPathTypeNames = Set( pathTypes.map { String( reflecting: $0 ) } )
    }

    public func CreateAnimationController() -> ( any AnimationController )?
    {
        animationFactory?()
    }
}

@MainActor
open class RouteControllerVM<Path: RoutePath, VM: RouterViewModel, V: RouterView>: RouteController<Path, V>
{
    public required init()
    {
        super.init()
    }

    open func OnCreateViewModel( path: Path ) -> VM
    {
        preconditionFailure( "OnCreateViewModel(path:) must be implemented" )
    }

    open func OnCreateView( path: Path, viewModel: VM ) -> V
    {
        preconditionFailure( "OnCreateView(path:viewModel:) must be implemented" )
    }

    public final override func OnCreateView( path: Path ) -> V
    {
        preconditionFailure( "Use OnCreateView(path:viewModel:) for RouteControllerVM" )
    }

    open override func Prepare( entry: RouteEntry, path: Path, router: any Router )
    {
        let viewModel = OnCreateViewModel( path: path )
        viewModel.Prepare( router: router, resultProvider: entry.resultProvider )
        entry.viewModel = viewModel
    }

    open override func MakeRouterView( path: Path, entry: RouteEntry ) -> V
    {
        guard let viewModel = entry.viewModel as? VM else
        {
            preconditionFailure( "RouteEntry \(entry.id) does not contain \(VM.self)" )
        }

        return OnCreateView( path: path, viewModel: viewModel )
    }
}
