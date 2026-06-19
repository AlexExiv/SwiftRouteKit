@attached(member, names: named(OnCreateView), named(OnCreateViewModel))
@attached(extension)
public macro Route(
    uri: String = "",
    singleTop: RouteSingleTop = .none,
    animation: Any.Type = Never.self) = #externalMacro(module: "RouterSwiftUIMacros", type: "RouteMacro")

@attached(extension)
public macro UseMiddlewares(
    _ middlewares: Any.Type...) = #externalMacro(module: "RouterSwiftUIMacros", type: "UseMiddlewaresMacro")

@attached(extension)
public macro GlobalMiddleware(
    order: Int) = #externalMacro(module: "RouterSwiftUIMacros", type: "GlobalMiddlewareMacro")
