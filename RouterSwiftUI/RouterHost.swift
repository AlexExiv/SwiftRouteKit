import SwiftUI

public struct RouterHost<RootPath: RoutePath>: View
{
    @StateObject
    private var navigator = SwiftUINavigator()

    private let router: RouterSimple
    private let rootPath: RootPath?

    public init( router: RouterSimple, rootPath: RootPath? = nil )
    {
        self.router = router
        self.rootPath = rootPath
    }

    public var body: some View
    {
        NavigationStack( path: navigator.stackBinding ) {
            RouterRootView( navigator: navigator, router: router, rootPath: rootPath )
                .navigationDestination( for: RouteEntry.self ) {
                    RouterEntryView( entry: $0 )
                }
        }
        .sheet( item: navigator.sheetBinding ) {
            RouterEntryView( entry: $0 )
        }
        .sheet( item: navigator.bottomSheetBinding ) {
            RouterEntryView( entry: $0 )
                .presentationDetents( Detents( for: $0 ) )
        }
        .RouterFullScreenCover( item: navigator.fullScreenBinding )
        .environment( \.router, router )
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

    private func Detents( for entry: RouteEntry ) -> Set<PresentationDetent>
    {
        guard case .bottomSheet( let detents ) = entry.presentationStyle else { return [.medium, .large] }

        return detents
    }
}

private struct RouterRootView<RootPath: RoutePath>: View
{
    @ObservedObject
    var navigator: SwiftUINavigator

    let router: RouterSimple
    let rootPath: RootPath?

    var body: some View
    {
        Group {
            if let root = navigator.root
            {
                RouterEntryView( entry: root )
            }
            else
            {
                Color.clear
            }
        }
        .environment( \.router, router )
    }
}

public struct RouterEntryView: View
{
    public let entry: RouteEntry

    public init( entry: RouteEntry )
    {
        self.entry = entry
    }

    public var body: some View
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

    let router: RouterSimple
    let rootPath: AnyRoutePath?

    var body: some View
    {
        NavigationStack( path: navigator.stackBinding ) {
            Group {
                if let root = navigator.root
                {
                    RouterEntryView( entry: root )
                }
                else
                {
                    Color.clear
                }
            }
            .navigationDestination( for: RouteEntry.self ) {
                RouterEntryView( entry: $0 )
            }
        }
        .sheet( item: navigator.sheetBinding ) {
            RouterEntryView( entry: $0 )
        }
        .sheet( item: navigator.bottomSheetBinding ) {
            RouterEntryView( entry: $0 )
                .presentationDetents( Detents( for: $0 ) )
        }
        .RouterFullScreenCover( item: navigator.fullScreenBinding )
        .environment( \.router, router )
        .onAppear {
            router.BindExecutor( SwiftUICommandExecutor( navigator: navigator ) )
            if let rootPath, router.isEmpty
            {
                _ = router.Route( path: rootPath, resultBinding: nil, replace: false )
            }
        }
        .onDisappear {
            router.UnbindExecutor()
        }
        .onChange( of: navigator.visibleEntryIDs ) {
            router.SyncVisibleEntries( $0 )
        }
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
    func RouterFullScreenCover( item: Binding<RouteEntry?> ) -> some View
    {
        #if os(iOS)
        fullScreenCover( item: item ) {
            RouterEntryView( entry: $0 )
        }
        #else
        sheet( item: item ) {
            RouterEntryView( entry: $0 )
        }
        #endif
    }
}
