import Combine
import Foundation

@MainActor
public protocol Router: AnyObject
{
    var key: String { get }
    var topRouter: ( any Router )? { get }
    var hasPreviousScreen: Bool { get }
    var lockBack: Bool { get set }

    @discardableResult
    func Route<Path: RoutePath>( _ path: Path ) -> ( any Router )?

    @discardableResult
    func Route( url: String ) -> ( any Router )?

    @discardableResult
    func RouteWithResult<Path: RoutePath, Result>( _ path: Path, result: @escaping ( Result ) -> Void ) -> ( any Router )?

    @discardableResult
    func Replace<Path: RoutePath>( _ path: Path ) -> ( any Router )?

    @discardableResult
    func Back() -> ( any Router )?

    @discardableResult
    func Close() -> ( any Router )?

    @discardableResult
    func CloseTo( key: String ) -> ( any Router )?

    @discardableResult
    func CloseToTop() -> ( any Router )?

    func BindExecutor( _ executor: any CommandExecutor )
    func UnbindExecutor()
}

@MainActor
public final class RouterSimple: Router, ObservableObject
{
    public let key: String
    public let registry: RouteRegistry
    public let commandBuffer = CommandBuffer()
    public let routerStack = RouterStack()

    public private( set ) weak var parent: RouterSimple?
    public private( set ) weak var routerTabs: RouterTabs?
    public private( set ) var tabIndex: Int?

    @Published
    public private( set ) var viewStack = [RouteEntry]()

    private var tabsByViewKey = [String: RouterTabs]()
    private var rootPath: AnyRoutePath?

    public init(
        registry: RouteRegistry,
        parent: RouterSimple? = nil,
        tabIndex: Int? = nil,
        routerTabs: RouterTabs? = nil,
        key: String = UUID().uuidString )
    {
        self.registry = registry
        self.parent = parent
        self.tabIndex = tabIndex
        self.routerTabs = routerTabs
        self.key = key
    }

    public var topRouter: ( any Router )?
    {
        rootRouter.FindTopRouter()
    }

    public var hasPreviousScreen: Bool
    {
        parent != nil || viewStack.count > 1
    }

    public var lockBack: Bool
    {
        get { viewStack.last?.lockBack ?? false }
        set { viewStack.last?.lockBack = newValue }
    }

    public var isEmpty: Bool
    {
        viewStack.isEmpty
    }

    public var rootRouter: RouterSimple
    {
        parent?.rootRouter ?? self
    }

    @discardableResult
    public func Route<Path: RoutePath>( _ path: Path ) -> ( any Router )?
    {
        Route( path: AnyRoutePath( path ), resultBinding: nil, replace: false )
    }

    @discardableResult
    public func Route( url: String ) -> ( any Router )?
    {
        do
        {
            let resolved = try registry.Resolve( url: url )
            return Route(
                path: resolved.path,
                controller: resolved.controller,
                resultBinding: nil,
                replace: false )
        }
        catch
        {
            assertionFailure( String( describing: error ) )
            return nil
        }
    }

    @discardableResult
    public func RouteWithResult<Path: RoutePath, Result>( _ path: Path, result: @escaping ( Result ) -> Void ) -> ( any Router )?
    {
        Route(
            path: AnyRoutePath( path ),
            resultBinding: RouteResultBinding( result ),
            replace: false )
    }

    @discardableResult
    public func Replace<Path: RoutePath>( _ path: Path ) -> ( any Router )?
    {
        Route( path: AnyRoutePath( path ), resultBinding: nil, replace: true )
    }

    @discardableResult
    public func Back() -> ( any Router )?
    {
        CloseCurrent( checkLock: true, closeChain: false )
    }

    @discardableResult
    public func Close() -> ( any Router )?
    {
        CloseCurrent( checkLock: false, closeChain: true )
    }

    @discardableResult
    public func CloseTo( key: String ) -> ( any Router )?
    {
        if let index = viewStack.firstIndex( where: { $0.id == key } )
        {
            CloseNoStackPresentations()
            guard index < viewStack.count else { return ThisOrParent() }

            let removed = viewStack.suffix( from: index + 1 )
            viewStack.removeLast( removed.count )
            commandBuffer.Apply( .closeTo( key ) )
            return self
        }

        for ( ownerKey, tabs ) in tabsByViewKey
        {
            if tabs.CloseTo( key: key )
            {
                _ = CloseTo( key: ownerKey )
                return tabs.selectedRouter
            }
        }

        if let parent
        {
            viewStack.removeAll()
            commandBuffer.Apply( .closeAll )
            return parent.CloseTo( key: key )
        }

        return CloseToTop()
    }

    @discardableResult
    public func CloseToTop() -> ( any Router )?
    {
        if parent == nil
        {
            guard let first = viewStack.first else { return self }

            viewStack = [first]
            commandBuffer.Apply( .closeTo( first.id ) )
            return self
        }

        viewStack.removeAll()
        commandBuffer.Apply( .closeAll )
        return parent?.CloseToTop()
    }

    public func BindExecutor( _ executor: any CommandExecutor )
    {
        commandBuffer.Bind( executor: executor )
        SyncExecutor()
    }

    public func UnbindExecutor()
    {
        commandBuffer.Unbind()
    }

    public func SyncVisibleEntries( _ ids: [String] )
    {
        let visible = Set( ids )
        let removed = viewStack.filter { visible.contains( $0.id ) == false }
        guard removed.isEmpty == false else { return }

        for entry in removed
        {
            TryCloseMiddlewares( entry: entry )
            tabsByViewKey[entry.id]?.ReleaseRouters()
            tabsByViewKey[entry.id] = nil
        }

        viewStack.removeAll { visible.contains( $0.id ) == false }
    }

    public func CreateTabs( viewKey: String, descriptors: [RouterTabDescriptor], tabRouteInParent: Bool = false, backToFirst: Bool = true, tabUnique: RouteTabUnique = .class ) -> RouterTabs
    {
        if let tabs = tabsByViewKey[viewKey]
        {
            tabs.Update( descriptors: descriptors )
            return tabs
        }

        let tabs = RouterTabs(
            parent: self,
            viewKey: viewKey,
            descriptors: descriptors,
            tabRouteInParent: tabRouteInParent,
            backToFirst: backToFirst,
            tabUnique: tabUnique )

        tabsByViewKey[viewKey] = tabs
        routerStack.PushReel( viewKey: viewKey )
        return tabs
    }

    func TryRouteMiddlewares(
        next: RouteParams,
        targetController: any AnyRouteController ) -> Bool
    {
        if let current = viewStack.last
        {
            if current.controller.OnBeforeRoute( router: self, current: current.path, next: next )
            {
                return true
            }

            for middleware in current.controller.localMiddlewares + registry.globalMiddlewares
            {
                if middleware.OnBeforeRoute( router: self, current: current.path, next: next )
                {
                    return true
                }
            }
        }

        if targetController.OnRoute( router: self, previous: viewStack.last?.path, next: next )
        {
            return true
        }

        for middleware in targetController.localMiddlewares + registry.globalMiddlewares
        {
            if middleware.OnRoute( router: self, previous: viewStack.last?.path, next: next )
            {
                return true
            }
        }

        return false
    }

    @discardableResult
    func Route( path: AnyRoutePath, resultBinding: RouteResultBinding?, replace: Bool ) -> ( any Router )?
    {
        guard let controller = registry.Controller( for: path ) else
        {
            assertionFailure( RouterError.routeNotFound( path ).description )
            return nil
        }

        return Route(
            path: path,
            controller: controller,
            resultBinding: resultBinding,
            replace: replace )
    }

    @discardableResult
    private func Route( path: AnyRoutePath, controller: any AnyRouteController, resultBinding: RouteResultBinding?, replace: Bool ) -> ( any Router )?
    {
        if routerTabs != nil, ShouldRouteInParent( controller: controller )
        {
            return parent?.Route( path: path, controller: controller, resultBinding: resultBinding, replace: replace )
        }

        let params = RouteParams( path: path, isReplace: replace )
        if TryRouteMiddlewares( next: params, targetController: controller )
        {
            return nil
        }

        if replace
        {
            return DoReplace( path: path, controller: controller, resultBinding: resultBinding )
        }

        if case .push = controller.presentationStyle, let tabRouter = TryRouteToExistingTab( path: path )
        {
            return tabRouter
        }

        if controller.singleTop != .none, let existing = rootRouter.FindExisting( path: path, singleTop: controller.singleTop )
        {
            return existing.router.CloseTo( key: existing.entryID )
        }

        do
        {
            let entry = try controller.MakeEntry( path: path, router: self, resultBinding: resultBinding )
            Append( entry )
            return self
        }
        catch
        {
            assertionFailure( String( describing: error ) )
            return nil
        }
    }

    private func Append( _ entry: RouteEntry )
    {
        if viewStack.isEmpty
        {
            rootPath = entry.path
        }

        viewStack.append( entry )
        routerStack.Push( viewKey: entry.id, routerKey: key )

        switch entry.presentationStyle
        {
        case .push:
            if viewStack.count == 1
            {
                commandBuffer.Apply( .setRoot( entry ) )
            }
            else
            {
                commandBuffer.Apply( .push( entry ) )
            }
        case .dialog:
            commandBuffer.Apply( .presentDialog( entry ) )
        case .fullScreen:
            commandBuffer.Apply( .presentFullScreen( entry ) )
        case .bottomSheet:
            commandBuffer.Apply( .presentBottomSheet( entry ) )
        }
    }

    private func DoReplace( path: AnyRoutePath, controller: any AnyRouteController, resultBinding: RouteResultBinding? ) -> ( any Router )?
    {
        let replacing = viewStack.popLast()?.id

        do
        {
            let entry = try controller.MakeEntry( path: path, router: self, resultBinding: resultBinding )
            viewStack.append( entry )
            commandBuffer.Apply( replacing == nil ? .setRoot( entry ) : .replace( entry, replacing: replacing ) )
            return self
        }
        catch
        {
            assertionFailure( String( describing: error ) )
            return nil
        }
    }

    private func CloseCurrent( checkLock: Bool, closeChain: Bool ) -> ( any Router )?
    {
        guard hasPreviousScreen else { return self }

        guard checkLock == false || lockBack == false else { return self }

        if let tabs = routerTabs, viewStack.count <= 1
        {
            return tabs.CloseFromTab( index: tabIndex ?? 0 )
        }

        guard let entry = viewStack.popLast() else { return ThisOrParent() }

        TryCloseMiddlewares( entry: entry )
        commandBuffer.Apply( .close( entry ) )

        if closeChain,
           let chainEntry = viewStack.last( where: { $0.controller.IsPartOfChain( path: entry.path ) } )
        {
            return CloseTo( key: chainEntry.id )
        }

        return ThisOrParent()
    }

    private func CloseNoStackPresentations()
    {
        while let last = viewStack.last, last.presentationStyle.isNoStackPresentation
        {
            _ = Close()
        }
    }

    private func TryCloseMiddlewares( entry: RouteEntry )
    {
        let previous = viewStack.last?.path
        if entry.controller.OnClose( router: self, current: entry.path, previous: previous )
        {
            return
        }

        for middleware in entry.controller.localMiddlewares + registry.globalMiddlewares
        {
            if middleware.OnClose( router: self, current: entry.path, previous: previous )
            {
                return
            }
        }
    }

    private func SyncExecutor()
    {
        let removed = commandBuffer.Sync( entries: viewStack.map( \.id ) )
        guard removed.isEmpty == false else { return }

        viewStack.removeAll { removed.contains( $0.id ) }
    }

    private func ShouldRouteInParent( controller: any AnyRouteController ) -> Bool
    {
        guard let tabs = routerTabs else { return false }

        return tabs.tabRouteInParent || controller.presentationStyle.isNoStackPresentation
    }

    private func TryRouteToExistingTab( path: AnyRoutePath ) -> RouterSimple?
    {
        guard let tabs = tabsByViewKey[viewStack.last?.id ?? ""] else { return nil }

        return tabs.RouteToRootIfNeeded( path: path )
    }

    private func FindExisting( path: AnyRoutePath, singleTop: RouteSingleTop ) -> RouteSearchResult?
    {
        for entry in viewStack
        {
            if PathsEqual( entry.path, path, singleTop: singleTop )
            {
                return RouteSearchResult( router: self, entryID: entry.id )
            }

            if let result = tabsByViewKey[entry.id]?.FindExisting( path: path, singleTop: singleTop )
            {
                return result
            }
        }

        return nil
    }

    private func FindTopRouter() -> RouterSimple
    {
        for entry in viewStack.reversed()
        {
            if let tabs = tabsByViewKey[entry.id]
            {
                return tabs.selectedRouter.FindTopRouter()
            }
        }

        return self
    }

    private func PathsEqual( _ lhs: AnyRoutePath, _ rhs: AnyRoutePath, singleTop: RouteSingleTop ) -> Bool
    {
        switch singleTop
        {
        case .none:
            return false
        case .class:
            return lhs.IsSameType( as: rhs )
        case .equal:
            return lhs == rhs
        }
    }

    private func ThisOrParent() -> ( any Router )?
    {
        viewStack.isEmpty ? parent : self
    }
}

struct RouteSearchResult
{
    let router: RouterSimple
    let entryID: String
}

public enum RouterFactory
{
    @MainActor
    public static func Make( registry: RouteRegistry ) -> RouterSimple
    {
        RouterSimple( registry: registry )
    }
}
