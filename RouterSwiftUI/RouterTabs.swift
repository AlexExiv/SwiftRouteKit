import Combine
import Foundation
import SwiftUI

public struct RouterTabDescriptor: Identifiable
{
    public let id: String
    public let index: Int
    public let title: String
    public let systemImage: String?
    public let rootPath: AnyRoutePath

    public init<Path: RoutePath>( id: String, index: Int, title: String, systemImage: String? = nil, rootPath: Path )
    {
        self.id = id
        self.index = index
        self.title = title
        self.systemImage = systemImage
        self.rootPath = AnyRoutePath( rootPath )
    }
}

@MainActor
public final class RouterTabs: ObservableObject
{
    public let parent: RouterSimple
    public let viewKey: String
    public let tabRouteInParent: Bool
    public let backToFirst: Bool
    public let tabUnique: RouteTabUnique

    @Published
    public private(set) var tabIndex: Int = 0

    public var tabChangeCallback: ((Int) -> Void)?

    public private(set) var descriptors: [RouterTabDescriptor]

    private var routers = [Int: RouterTabSimple]()

    init( parent: RouterSimple, viewKey: String, descriptors: [RouterTabDescriptor], tabRouteInParent: Bool, backToFirst: Bool, tabUnique: RouteTabUnique )
    {
        self.parent = parent
        self.viewKey = viewKey
        self.descriptors = descriptors.sorted { $0.index < $1.index }
        self.tabRouteInParent = tabRouteInParent
        self.backToFirst = backToFirst
        self.tabUnique = tabUnique
    }

    public var selectedRouter: RouterTabSimple
    {
        Router( for: tabIndex )
    }

    public func Update( descriptors: [RouterTabDescriptor] )
    {
        self.descriptors = descriptors.sorted { $0.index < $1.index }
    }

    public func Router( for descriptor: RouterTabDescriptor ) -> RouterTabSimple
    {
        Router( for: descriptor.index )
    }

    public func Router( for index: Int ) -> RouterTabSimple
    {
        if let router = routers[index]
        {
            return router
        }

        let router = RouterTabSimple( registry: parent.registry, parent: parent, tabIndex: index, routerTabs: self )
        routers[index] = router
        
        return router
    }

    @discardableResult
    public func Route<Path: RoutePath>( _ index: Int, path: Path, recreate: Bool = false ) -> RouterTabSimple
    {
        Route( index, path: AnyRoutePath( path ), recreate: recreate )
    }

    @discardableResult
    public func Route( _ index: Int, path: AnyRoutePath, recreate: Bool = false ) -> RouterTabSimple
    {
        let router = Router( for: index )

        if recreate
        {
            router.ReleaseAllEntries()
        }

        if router.viewStack.isEmpty
        {
            _ = router.Route( RouteParams( path: path ) )
        }

        return router
    }

    @discardableResult
    public func Route( _ index: Int ) -> Bool
    {
        guard index != tabIndex else { return true }

        guard let descriptor = descriptors.first( where: { $0.index == index } ),
              let controller = parent.registry.Controller( for: descriptor.rootPath ) else { return false }

        let params = RouteParams( path: descriptor.rootPath, tabIndex: index )
        guard parent.TryRouteMiddlewares( next: params, targetController: controller ) == false else { return false }

        tabIndex = index
        parent.commandBuffer.Apply( .selectTab( viewKey: viewKey, index: index ) )
        tabChangeCallback?( index )
        
        return true
    }

    func CloseFromTab( index: Int ) -> ( any Router )?
    {
        if backToFirst, index != 0
        {
            Route( 0 )
            return Router( for: 0 )
        }

        return parent.Close()
    }

    func RouteToRootIfNeeded( path: AnyRoutePath ) -> RouterSimple?
    {
        guard let descriptor = descriptors.first( where: { PathsEqual( $0.rootPath, path ) } ) else { return nil }
        guard Route( descriptor.index ) else { return nil }

        let router = Route( descriptor.index, path: descriptor.rootPath )
        router.CloseTabToTop()
        
        return router
    }

    func FindExisting( path: AnyRoutePath, singleTop: RouteSingleTop ) -> RouteSearchResult?
    {
        for (index, router) in routers
        {
            if let result = router.FindExistingFromTabs( path: path, singleTop: singleTop )
            {
                Route( index )
                router.CloseTo( key: result.entryID )
                return result
            }
        }

        return nil
    }

    func CloseTo( key: String ) -> Bool
    {
        for ( index, router ) in routers
        {
            if router.viewStack.contains( where: { $0.id == key } )
            {
                Route( index )
                router.CloseTo( key: key )
                return true
            }
        }

        return false
    }

    func ReleaseRouters()
    {
        routers.values.forEach { $0.ReleaseAllEntries() }
        routers.removeAll()
    }

    private func PathsEqual( _ lhs: AnyRoutePath, _ rhs: AnyRoutePath ) -> Bool
    {
        switch tabUnique
        {
        case .none:
            return false
        case .class:
            return lhs.IsSameType( as: rhs )
        case .equal:
            return lhs == rhs
        }
    }
}

private extension RouterSimple
{
    func FindExistingFromTabs( path: AnyRoutePath, singleTop: RouteSingleTop ) -> RouteSearchResult?
    {
        for entry in viewStack
        {
            switch singleTop
            {
            case .none:
                continue
            case .class where entry.path.IsSameType( as: path ):
                return RouteSearchResult( router: self, entryID: entry.id )
            case .equal where entry.path == path:
                return RouteSearchResult( router: self, entryID: entry.id )
            default:
                continue
            }
        }

        return nil
    }
}
