import Foundation

@MainActor
public protocol RouterTab: Router
{
    var parent: RouterSimple? { get }
    var routerTabs: RouterTabs? { get }
    var tabIndex: Int { get }

    @discardableResult
    func CloseTabToTop() -> any RouterTab
}

@MainActor
public final class RouterTabSimple: RouterSimple, RouterTab
{
    public let tabIndex: Int
    public private(set) weak var routerTabs: RouterTabs?

    init( registry: RouteRegistry, parent: RouterSimple, tabIndex: Int, routerTabs: RouterTabs, key: String = UUID().uuidString )
    {
        self.tabIndex = tabIndex
        self.routerTabs = routerTabs

        super.init( registry: registry, parent: parent, key: key )
    }

    public override var hasPreviousScreen: Bool
    {
        viewStack.count > 1 || parent?.hasPreviousScreen == true
    }

    @discardableResult
    public override func Back() -> (any Router)?
    {
        if viewStack.count <= 1, !(parent is any RouterTab)
        {
            if lockBack
            {
                return self
            }

            return routerTabs?.CloseFromTab( index: tabIndex ) ?? self
        }

        return super.Back()
    }

    @discardableResult
    public override func Close() -> (any Router)?
    {
        if viewStack.count <= 1, !(parent is any RouterTab)
        {
            return routerTabs?.CloseFromTab( index: tabIndex ) ?? self
        }

        return super.Close()
    }

    @discardableResult
    public func CloseTabToTop() -> any RouterTab
    {
        Close( toIndex: 0 )
        return self
    }

    override func ShouldRouteInParent( controller: any AnyRouteController ) -> Bool
    {
        guard let routerTabs else { return false }

        return (routerTabs.tabRouteInParent && !viewStack.isEmpty) || controller.presentationStyle.isNoStackPresentation
    }

    override func RouteInParent( params: RouteParams, controller: any AnyRouteController, replace: Bool ) -> (any Router)?
    {
        parent?.Route( params: params, controller: controller, replace: replace )
    }

    override func TryRouteToExistingTab( path: AnyRoutePath ) -> RouterSimple?
    {
        if !viewStack.isEmpty, let router = routerTabs?.RouteToRootIfNeeded( path: path )
        {
            return router
        }

        return super.TryRouteToExistingTab( path: path )
    }
}
