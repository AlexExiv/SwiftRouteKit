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
    func Route<Path: RoutePath>( _ path: Path ) -> (any Router)?

    @discardableResult
    func Route( _ params: RouteParams ) -> (any Router)?

    @discardableResult
    func Route( url: String ) -> (any Router)?

    @discardableResult
    func RouteWithResult<Path: RoutePath, Result>( _ path: Path, result: @escaping ( Result ) -> Void ) -> (any Router)?

    func RouteForResult<Path: RoutePath, Result>( _ path: Path ) async -> Result?
    func RouteForResults<Path: RoutePath, Result>( _ path: Path, as type: Result.Type ) -> AsyncStream<Result>
    func RouteResultPublisher<Path: RoutePath, Result>( _ path: Path, as type: Result.Type ) -> AnyPublisher<Result, Never>

    @discardableResult
    func Replace<Path: RoutePath>( _ path: Path ) -> (any Router)?

    @discardableResult
    func Back() -> (any Router)?

    @discardableResult
    func Close() -> (any Router)?

    @discardableResult
    func CloseTo( key: String ) -> (any Router)?

    @discardableResult
    func CloseToTop() -> (any Router)?

    func BindExecutor( _ executor: any CommandExecutor )
    func UnbindExecutor()
}

@MainActor
public class RouterSimple: Router, ObservableObject
{
    public let key: String
    public let registry: RouteRegistry
    public let commandBuffer = CommandBuffer()
    public let routerStack = RouterStack()

    public private(set) weak var parent: RouterSimple?

    @Published
    public private(set) var viewStack = [RouteEntry]()

    private var tabsByViewKey = [String: RouterTabs]()
    private var rootPath: AnyRoutePath?

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

    public init( registry: RouteRegistry, parent: RouterSimple? = nil, key: String = UUID().uuidString )
    {
        self.registry = registry
        self.parent = parent
        self.key = key
    }

    @discardableResult
    public func Route<Path: RoutePath>( _ path: Path ) -> ( any Router )?
    {
        Route( RouteParams( path: path ) )
    }

    @discardableResult
    public func Route( _ params: RouteParams ) -> ( any Router )?
    {
        if params.isReplace
        {
            return Route( params: params, replace: true )
        }

        if let tabIndex = params.tabIndex
        {
            let tabs = tabsByViewKey[viewStack.last?.id ?? ""]
            tabs?.Route( tabIndex )
            return tabs?.Router( for: tabIndex )
        }

        return Route( params: params, replace: false )
    }

    @discardableResult
    public func Route( url: String ) -> ( any Router )?
    {
        do
        {
            let resolved = try registry.Resolve( url: url )
            return Route( params: RouteParams( path: resolved.path ), controller: resolved.controller, replace: false )
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
        Route( RouteParams( path: AnyRoutePath( path ), resultBinding: RouteResultBinding( result ) ) )
    }

    public func RouteForResult<Path: RoutePath, Result>( _ path: Path ) async -> Result?
    {
        await withCheckedContinuation { ( continuation: CheckedContinuation<Result?, Never> ) in
            let binding = RouteResultBinding(
                onDispatch: {
                    guard let result = $0 as? Result else { return false }

                    continuation.resume( returning: result )
                    return true
                },
                onComplete: {
                    continuation.resume( returning: nil )
                } )

            Route( RouteParams( path: AnyRoutePath( path ), resultBinding: binding ) )
        }
    }

    public func RouteForResults<Path: RoutePath, Result>( _ path: Path, as type: Result.Type ) -> AsyncStream<Result>
    {
        let resultStream = AsyncStream<Result>.makeStream(of: Result.self)
        let binding = RouteResultBinding(
            onDispatch: {
                guard let result = $0 as? Result else { return false }

                resultStream.continuation.yield( result )
                return false
            },
            onComplete: {
                resultStream.continuation.finish()
            } )

        Route( RouteParams( path: AnyRoutePath( path ), resultBinding: binding ) )

        return resultStream.stream
    }

    public func RouteResultPublisher<Path: RoutePath, Result>( _ path: Path, as type: Result.Type ) -> AnyPublisher<Result, Never>
    {
        let subject = PassthroughSubject<Result, Never>()
        let binding = RouteResultBinding(
            onDispatch: {
                guard let result = $0 as? Result else { return false }

                subject.send( result )
                return false
            },
            onComplete: {
                subject.send( completion: .finished )
            } )

        Route( RouteParams( path: AnyRoutePath( path ), resultBinding: binding ) )

        return subject.eraseToAnyPublisher()
    }

    @discardableResult
    public func Replace<Path: RoutePath>( _ path: Path ) -> (any Router)?
    {
        Route( RouteParams( path: path, isReplace: true ) )
    }

    @discardableResult
    public func Back() -> (any Router)?
    {
        CloseCurrent( checkLock: true, closeChain: false )
    }

    @discardableResult
    public func Close() -> (any Router)?
    {
        CloseCurrent( checkLock: false, closeChain: true )
    }

    @discardableResult
    public func CloseTo( key: String ) -> (any Router)?
    {
        if let index = viewStack.firstIndex( where: { $0.id == key } )
        {
            CloseNoStackPresentations()
            guard index < viewStack.count else { return ThisOrParent() }

            Remove( entries: Array( viewStack.suffix( from: index + 1 ) ) )
            commandBuffer.Apply( .closeTo( key ) )
            return self
        }

        for ( ownerKey, tabs ) in tabsByViewKey
        {
            if tabs.CloseTo( key: key )
            {
                CloseTo( key: ownerKey )
                return tabs.selectedRouter
            }
        }

        if let parent
        {
            ReleaseAllEntries()
            return parent.CloseTo( key: key )
        }

        return CloseToTop()
    }

    @discardableResult
    public func CloseToTop() -> ( any Router )?
    {
        if parent == nil
        {
            return Close( toIndex: 0 )
        }

        ReleaseAllEntries()
        return parent?.CloseToTop()
    }

    @discardableResult
    func Close( toIndex: Int ) -> RouterSimple
    {
        if !viewStack.indices.contains( toIndex )
        {
            return self
        }

        let entry = viewStack[toIndex]
        let entries = Array( viewStack.suffix( from: toIndex + 1 ) )
        if entries.isEmpty
        {
            return self
        }

        Remove( entries: entries )
        commandBuffer.Apply( .closeTo( entry.id ) )
        return self
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
        Remove( entries: removed )
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

    func ReleaseAllEntries()
    {
        Remove( entries: viewStack )
        commandBuffer.Apply( .closeAll )
    }

    func Remove( entries: [RouteEntry] )
    {
        if entries.isEmpty
        {
            return
        }
        
        CleanupRemovedEntries( entries )
        let ids = Set( entries.map(\.id) )
        viewStack.removeAll { ids.contains( $0.id ) }
    }

    func TryRouteMiddlewares( next: RouteParams, targetController: any AnyRouteController ) -> Bool
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
    func Route( params: RouteParams, replace: Bool ) -> ( any Router )?
    {
        guard let controller = registry.Controller( for: params.path ) else
        {
            assertionFailure( RouterError.routeNotFound( params.path ).description )
            return nil
        }

        return Route( params: params, controller: controller, replace: replace )
    }

    @discardableResult
    func Route( params: RouteParams, controller: any AnyRouteController, replace: Bool ) -> ( any Router )?
    {
        if ShouldRouteInParent( controller: controller )
        {
            return RouteInParent( params: params, controller: controller, replace: replace )
        }

        if TryRouteMiddlewares( next: params, targetController: controller )
        {
            return nil
        }

        if replace
        {
            return DoReplace( params: params, controller: controller )
        }

        if case .push = controller.presentationStyle, let tabRouter = TryRouteToExistingTab( path: params.path )
        {
            return tabRouter
        }

        if controller.singleTop != .none, let existing = rootRouter.FindExisting( path: params.path, singleTop: controller.singleTop )
        {
            return existing.router.CloseTo( key: existing.entryID )
        }

        do
        {
            let entry = try controller.MakeEntry( path: params.path, router: self, resultBinding: params.resultBinding )
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

    private func DoReplace( params: RouteParams, controller: any AnyRouteController ) -> ( any Router )?
    {
        do
        {
            let entry = try controller.MakeEntry( path: params.path, router: self, resultBinding: params.resultBinding )

            let replacing = viewStack.last
            if let replacing
            {
                _ = viewStack.popLast()
                CleanupRemovedEntry( replacing )
            }

            viewStack.append( entry )
            commandBuffer.Apply( replacing == nil ? .setRoot( entry ) : .replace( entry, replacing: replacing?.id ) )
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

        guard let entry = viewStack.popLast() else { return ThisOrParent() }

        CleanupRemovedEntry( entry )
        commandBuffer.Apply( .close( entry ) )

        if closeChain, let chainEntry = viewStack.last( where: { $0.controller.IsPartOfChain( path: entry.path ) } )
        {
            return CloseTo( key: chainEntry.id )
        }

        return ThisOrParent()
    }

    private func CloseNoStackPresentations()
    {
        while let last = viewStack.last, last.presentationStyle.isNoStackPresentation
        {
            Close()
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

    private func CleanupRemovedEntries( _ entries: [RouteEntry] )
    {
        entries.reversed().forEach { CleanupRemovedEntry( $0 ) }
    }

    private func CleanupRemovedEntry( _ entry: RouteEntry )
    {
        TryCloseMiddlewares( entry: entry )
        tabsByViewKey[entry.id]?.ReleaseRouters()
        tabsByViewKey[entry.id] = nil
    }

    private func SyncExecutor()
    {
        let removed = commandBuffer.Sync( entries: viewStack.map( \.id ) )
        guard removed.isEmpty == false else { return }

        let removedEntries = viewStack.filter { removed.contains( $0.id ) }
        Remove( entries: removedEntries )
    }

    func ShouldRouteInParent( controller: any AnyRouteController ) -> Bool
    {
        false
    }

    func RouteInParent( params: RouteParams, controller: any AnyRouteController, replace: Bool ) -> ( any Router )?
    {
        parent?.Route( params: params, controller: controller, replace: replace )
    }

    func TryRouteToExistingTab( path: AnyRoutePath ) -> RouterSimple?
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
