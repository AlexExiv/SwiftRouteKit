import Foundation

public struct RouteRegistration
{
    let controller: any AnyRouteController
    let uri: String?
    let singleTop: RouteSingleTop
    let animationFactory: ( @MainActor () -> ( any AnimationController )? )?
    let middlewareFactories: [@MainActor () -> any MiddlewareController]

    @MainActor
    public init(
        _ controller: any AnyRouteController,
        uri: String = "",
        singleTop: RouteSingleTop = .none,
        animationType: ( any AnimationController.Type )? = nil,
        middlewareTypes: [any MiddlewareController.Type] = [] )
    {
        self.controller = controller
        self.uri = uri.isEmpty ? nil : uri
        self.singleTop = singleTop
        self.animationFactory = animationType.map( Self.AnimationFactory )
        self.middlewareFactories = middlewareTypes.map( Self.MiddlewareFactory )
    }

    private static func AnimationFactory( _ type: any AnimationController.Type ) -> @MainActor () -> ( any AnimationController )?
    {
        { type.init() }
    }

    private static func MiddlewareFactory( _ type: any MiddlewareController.Type ) -> @MainActor () -> any MiddlewareController
    {
        { type.init() }
    }
}

public struct ResolvedRoute
{
    public let controller: any AnyRouteController
    public let path: AnyRoutePath
}

@MainActor
public final class RouteRegistry
{
    public private( set ) var controllers: [any AnyRouteController] = []
    public private( set ) var globalMiddlewares: [any MiddlewareController] = []

    private var urlPatternsByController = [ObjectIdentifier: RouteURLPattern]()

    public init()
    {
    }

    public convenience init(
        routes: [RouteRegistration],
        globalMiddlewares: [GlobalMiddlewareRegistration] = [] ) throws
    {
        self.init()
        try Configure( routes: routes, globalMiddlewares: globalMiddlewares )
    }

    public func Controller( for path: AnyRoutePath ) -> ( any AnyRouteController )?
    {
        controllers.first { $0.CanHandle( path: path ) }
    }

    public func Resolve( url: String ) throws -> ResolvedRoute
    {
        for controller in controllers
        {
            let key = ObjectIdentifier( controller )
            guard let pattern = urlPatternsByController[key], let match = pattern.Match( url ) else { continue }

            return ResolvedRoute( controller: controller, path: try controller.Path( from: match ) )
        }

        throw RouterError.urlNotFound( url )
    }

    private func Configure(
        routes: [RouteRegistration],
        globalMiddlewares: [GlobalMiddlewareRegistration] ) throws
    {
        try routes.forEach { try Register( $0 ) }
        self.globalMiddlewares = globalMiddlewares
            .sorted { $0.order < $1.order }
            .map { $0.factory() }
    }

    private func Register( _ registration: RouteRegistration ) throws
    {
        let pathName = registration.controller.pathTypeName
        guard controllers.contains( where: { $0.pathTypeName == pathName } ) == false else
        {            throw RouterError.duplicatePath( pathName )
        }

        if let uri = registration.uri
        {
            guard urlPatternsByController.values.contains( where: { $0.rawValue == uri } ) == false else
            {                throw RouterError.duplicateURI( uri )
            }

            urlPatternsByController[ObjectIdentifier( registration.controller )] = try RouteURLPattern( uri )
        }

        registration.controller.Configure(
            uri: registration.uri,
            singleTop: registration.singleTop,
            animationFactory: registration.animationFactory,
            middlewareFactories: registration.middlewareFactories )

        controllers.append( registration.controller )
    }
}
