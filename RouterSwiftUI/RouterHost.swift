import SwiftUI

public struct RouterHost<RootPath: RoutePath>: View
{
    @StateObject
    private var navigator = SwiftUINavigator()

    @StateObject
    private var navigationBarStore = RouterNavigationBarStore()

    @Environment( \.routerNavigationBarProvider )
    private var navigationBarProvider

    private let router: RouterSimple
    private let rootPath: RootPath?

    public init( router: RouterSimple, rootPath: RootPath? = nil )
    {
        self.router = router
        self.rootPath = rootPath
    }

    public var body: some View
    {
        RootContent()
            .sheet( item: navigator.sheetBinding ) {
                RouterEntryView( entry: $0 )
            }
            .sheet( item: navigator.bottomSheetBinding ) {
                RouterEntryView( entry: $0 )
                    .presentationDetents( Detents( for: $0 ) )
            }
            .RouterFullScreenCover( item: navigator.fullScreenBinding ) {
                NavigationEntryContent( $0, canGoBack: router.hasPreviousScreen )
            }
            .environment( \.router, router )
            .environment( \.routerNavigationBarStore, navigationBarStore )
            .onAppear {
                router.BindExecutor( SwiftUICommandExecutor( navigator: navigator ) )
                if let rootPath, router.isEmpty
                {
                    router.Route( rootPath )
                }
            }
            .onDisappear {
                router.UnbindExecutor()
            }
            .onChange( of: navigator.visibleEntryIDs ) {
                router.SyncVisibleEntries( $0 )
            }
    }

    @ViewBuilder
    private func RootContent() -> some View
    {
        if navigator.root?.containerStyle == .tabs
        {
            TabsRootContent()
        }
        else
        {
            NavigationStack( path: RouterStackBinding( navigator: navigator, router: router ) ) {
                NavigationRootContent()
                    .navigationDestination( for: RouteEntry.self ) {
                        NavigationEntryContent( $0 )
                    }
            }
        }
    }

    @ViewBuilder
    private func TabsRootContent() -> some View
    {
        ZStack
        {
            if let root = navigator.root
            {
                RouterEntryView( entry: root )
            }
            else
            {
                Color.clear
            }

            NavigationStack( path: RouterStackBinding( navigator: navigator, router: router ) ) {
                Color.clear
                    .navigationDestination( for: RouteEntry.self ) {
                        NavigationEntryContent( $0, canGoBack: true )
                    }
            }
            .opacity( navigator.stack.isEmpty ? 0 : 1 )
            .allowsHitTesting( navigator.stack.isEmpty == false )
        }
    }

    @ViewBuilder
    private func NavigationRootContent() -> some View
    {
        if let root = navigator.root
        {
            NavigationEntryContent( root )
        }
        else
        {
            Color.clear
        }
    }

    private func NavigationEntryContent( _ entry: RouteEntry ) -> some View
    {
        NavigationEntryContent( entry, canGoBack: navigator.stack.isEmpty == false )
    }

    private func NavigationEntryContent( _ entry: RouteEntry, canGoBack: Bool ) -> some View
    {
        RouterNavigationBarEntryHost(
            store: navigationBarStore,
            provider: navigationBarProvider,
            entry: entry,
            canGoBack: canGoBack,
            back: { _ = router.Back() } ) {
                RouterEntryView( entry: entry )
            }
            .environment( \.routerNavigationBarStore, navigationBarStore )
    }

    private func Detents( for entry: RouteEntry ) -> Set<PresentationDetent>
    {
        guard case .bottomSheet( let detents ) = entry.presentationStyle else { return [.medium, .large] }

        return detents
    }

}

public struct RouterEntryView: View
{
    public let entry: RouteEntry

    public init( entry: RouteEntry )
    {
        self.entry = entry
    }

    @ViewBuilder
    public var body: some View
    {
        if let router = entry.router
        {
            Content()
                .environment( \.router, router )
        }
        else
        {
            Content()
        }
    }

    private func Content() -> some View
    {
        Group {
            if let view = try? entry.controller.MakeView( entry: entry )
            {
                view
            }
            else
            {
                EmptyView()
            }
        }
        .environment( \.routeEntry, entry )
    }
}

public struct AnyRouterHost: View
{
    private let router: RouterSimple
    private let rootPath: AnyRoutePath?

    public init( router: RouterSimple, rootPath: AnyRoutePath? = nil )
    {
        self.router = router
        self.rootPath = rootPath
    }

    public var body: some View
    {
        _AnyRouterHost( router: router, rootPath: rootPath )
    }
}

private struct _AnyRouterHost: View
{
    @StateObject
    private var navigator = SwiftUINavigator()

    @StateObject
    private var navigationBarStore = RouterNavigationBarStore()

    @Environment( \.routerNavigationBarProvider )
    private var navigationBarProvider

    let router: RouterSimple
    let rootPath: AnyRoutePath?

    var body: some View
    {
        RootContent()
            .sheet( item: navigator.sheetBinding ) {
                RouterEntryView( entry: $0 )
            }
            .sheet( item: navigator.bottomSheetBinding ) {
                RouterEntryView( entry: $0 )
                    .presentationDetents( Detents( for: $0 ) )
            }
            .RouterFullScreenCover( item: navigator.fullScreenBinding ) {
                NavigationEntryContent( $0, canGoBack: router.hasPreviousScreen )
            }
            .environment( \.router, router )
            .environment( \.routerNavigationBarStore, navigationBarStore )
            .onAppear {
                router.BindExecutor( SwiftUICommandExecutor( navigator: navigator ) )
                if let rootPath, router.isEmpty
                {
                    router.Route( RouteParams( path: rootPath ) )
                }
            }
            .onDisappear {
                router.UnbindExecutor()
            }
            .onChange( of: navigator.visibleEntryIDs ) {
                router.SyncVisibleEntries( $0 )
            }
    }

    @ViewBuilder
    private func RootContent() -> some View
    {
        if navigator.root?.containerStyle == .tabs
        {
            TabsRootContent()
        }
        else
        {
            NavigationStack( path: RouterStackBinding( navigator: navigator, router: router ) ) {
                NavigationRootView()
                    .navigationDestination( for: RouteEntry.self ) {
                        NavigationEntryContent( $0 )
                    }
            }
        }
    }

    @ViewBuilder
    private func TabsRootContent() -> some View
    {
        ZStack
        {
            if let root = navigator.root
            {
                RouterEntryView( entry: root )
            }
            else
            {
                Color.clear
            }

            NavigationStack( path: RouterStackBinding( navigator: navigator, router: router ) ) {
                Color.clear
                    .navigationDestination( for: RouteEntry.self ) {
                        NavigationEntryContent( $0, canGoBack: true )
                    }
            }
            .opacity( navigator.stack.isEmpty ? 0 : 1 )
            .allowsHitTesting( navigator.stack.isEmpty == false )
        }
    }

    @ViewBuilder
    private func NavigationRootView() -> some View
    {
        if let root = navigator.root
        {
            NavigationEntryContent( root )
        }
        else
        {
            Color.clear
        }
    }

    private func NavigationEntryContent( _ entry: RouteEntry ) -> some View
    {
        NavigationEntryContent( entry, canGoBack: navigator.stack.isEmpty == false )
    }

    private func NavigationEntryContent( _ entry: RouteEntry, canGoBack: Bool ) -> some View
    {
        RouterNavigationBarEntryHost(
            store: navigationBarStore,
            provider: navigationBarProvider,
            entry: entry,
            canGoBack: canGoBack,
            back: { _ = router.Back() } ) {
                RouterEntryView( entry: entry )
            }
            .environment( \.routerNavigationBarStore, navigationBarStore )
    }

    private func Detents( for entry: RouteEntry ) -> Set<PresentationDetent>
    {
        guard case .bottomSheet( let detents ) = entry.presentationStyle else { return [.medium, .large] }

        return detents
    }

}

private extension View
{
    @ViewBuilder
    func RouterFullScreenCover<Content: View>( item: Binding<RouteEntry?>, @ViewBuilder content: @escaping ( RouteEntry ) -> Content ) -> some View
    {
        #if os(iOS)
        fullScreenCover( item: item ) {
            content( $0 )
        }
        #else
        sheet( item: item ) {
            content( $0 )
        }
        #endif
    }
}

@MainActor
private func RouterStackBinding( navigator: SwiftUINavigator, router: RouterSimple ) -> Binding<[RouteEntry]>
{
    Binding(
        get: { navigator.stack },
        set: {
            let removedCount = navigator.stack.count - $0.count
            if removedCount <= 0
            {
                navigator.stack = $0
            }
            else
            {
                for _ in 0..<removedCount
                {
                    router.Back()
                }
            }
        } )
}
