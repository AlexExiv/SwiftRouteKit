import SwiftUI

private struct RouterEnvironmentKey: EnvironmentKey
{
    @MainActor
    static var defaultValue: any Router
    {
        RouterSimple( registry: RouteRegistry() )
    }
}

private struct RouteEntryEnvironmentKey: EnvironmentKey
{
    static var defaultValue: RouteEntry?
    {
        nil
    }
}

private struct RouterNavigationBarProviderEnvironmentKey: EnvironmentKey
{
    static var defaultValue: AnyRouterNavigationBarProvider?
    {
        nil
    }
}

private struct RouterNavigationBarStoreEnvironmentKey: EnvironmentKey
{
    static var defaultValue: RouterNavigationBarStore?
    {
        nil
    }
}

public extension EnvironmentValues
{
    var router: any Router
    {
        get { self[RouterEnvironmentKey.self] }
        set { self[RouterEnvironmentKey.self] = newValue }
    }

    var routeEntry: RouteEntry?
    {
        get { self[RouteEntryEnvironmentKey.self] }
        set { self[RouteEntryEnvironmentKey.self] = newValue }
    }

    internal var routerNavigationBarProvider: AnyRouterNavigationBarProvider?
    {
        get { self[RouterNavigationBarProviderEnvironmentKey.self] }
        set { self[RouterNavigationBarProviderEnvironmentKey.self] = newValue }
    }

    internal var routerNavigationBarStore: RouterNavigationBarStore?
    {
        get { self[RouterNavigationBarStoreEnvironmentKey.self] }
        set { self[RouterNavigationBarStoreEnvironmentKey.self] = newValue }
    }
}

public enum RouterPreview
{
    @MainActor
    public static func Router() -> RouterSimple
    {
        RouterSimple( registry: RouteRegistry() )
    }

    @MainActor
    public static func Router( registry: RouteRegistry ) -> RouterSimple
    {
        RouterSimple( registry: registry )
    }
}
