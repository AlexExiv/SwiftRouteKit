import SwiftUI
import RouterSwiftUI

public struct HomePath: RoutePath, EmptyParamsPath
{
    public init()
    {
    }
}

public struct ProfilePath: RoutePath
{
    public let id: Int

    public init( id: Int )
    {
        self.id = id
    }
}

public struct SettingsPath: RoutePath
{
    public let section: String

    public init( section: String )
    {
        self.section = section
    }
}

public struct MainTabsPath: RoutePath, EmptyParamsPath
{
    public init()
    {
    }
}

public struct FeedPath: RoutePath, EmptyParamsPath
{
    public init()
    {
    }
}

public struct SearchPath: RoutePath, EmptyParamsPath
{
    public init()
    {
    }
}

public struct DialogPath: RoutePath, EmptyParamsPath
{
    public init()
    {
    }
}

public struct BottomSheetPath: RoutePath, EmptyParamsPath
{
    public init()
    {
    }
}

public struct AuthPath: RoutePath, EmptyParamsPath
{
    public init()
    {
    }
}

@GlobalMiddleware( order: 0 )
public final class SampleGlobalMiddleware: MiddlewareController
{
    public init()
    {
    }

    public func OnRoute( router: any Router, previous: AnyRoutePath?, next: RouteParams ) -> Bool
    {
        false
    }
}

public final class AuthMiddleware: MiddlewareController
{
    public static var isAuthorized = false

    public init()
    {
    }

    public func OnRoute( router: any Router, previous: AnyRoutePath?, next: RouteParams ) -> Bool
    {
        guard next.path.Typed( ProfilePath.self ) != nil, Self.isAuthorized == false else { return false }

        router.Route( AuthPath() )
        return true
    }
}

public struct HomeView: RouterView
{
    @Environment( \.router )
    private var router

    public var body: some View
    {
        List {
            Button( "Profile" ) {
                router.Route( ProfilePath( id: 42 ) )
            }

            Button( "Tabs" ) {
                router.Route( MainTabsPath() )
            }

            Button( "Dialog" ) {
                router.Route( DialogPath() )
            }

            Button( "Bottom sheet" ) {
                router.Route( BottomSheetPath() )
            }
        }
        .navigationTitle( "Router" )
    }
}

public final class ProfileViewModel: RouterViewModel
{
    @Published
    public var title = ""

    public func Configure( id: Int )
    {
        title = "Profile \(id)"
    }
}

public struct ProfileView: RouterView
{
    @ObservedObject
    public var viewModel: ProfileViewModel

    public var body: some View
    {
        Text( viewModel.title )
            .navigationTitle( viewModel.title )
    }
}

public struct SettingsView: RouterView
{
    public let section: String

    public var body: some View
    {
        Text( "Settings \(section)" )
    }
}

public struct MainTabsView: RouterTabsView
{
    public var body: some View
    {
        RouterTabsHost( descriptors: [
            RouterTabDescriptor( id: "feed", index: 0, title: "Feed", systemImage: "list.bullet", rootPath: FeedPath() ),
            RouterTabDescriptor( id: "search", index: 1, title: "Search", systemImage: "magnifyingglass", rootPath: SearchPath() )
        ] )
    }
}

public struct FeedView: RouterView
{
    @Environment( \.router )
    private var router

    public var body: some View
    {
        Button( "Open search tab" ) {
            router.Route( SearchPath() )
        }
    }
}

public struct SearchView: RouterView
{
    public var body: some View
    {
        Text( "Search" )
    }
}

public struct SampleDialogView: RouterDialogView
{
    public var body: some View
    {
        Text( "Dialog" )
            .padding()
    }
}

public struct SampleBottomSheetView: RouterBottomSheetView
{
    public static let routerPresentationDetents: Set<PresentationDetent> = [.medium, .large]

    public var body: some View
    {
        Text( "Bottom sheet" )
            .padding()
    }
}

public struct AuthView: RouterView
{
    public var body: some View
    {
        Text( "Login" )
    }
}

@Route( uri: "/", singleTop: .equal )
public final class HomeRouteController: RouteController<HomePath, HomeView>
{
}

@Route( uri: "/profile/:id", singleTop: .class )
@UseMiddlewares( AuthMiddleware.self )
public final class ProfileRouteController: RouteControllerVM<ProfilePath, ProfileViewModel, ProfileView>
{
    public override func Convert( path: [String: String], query: [String: String] ) -> ProfilePath?
    {
        guard let id = Int( path["id"] ?? "" ) else { return nil }

        return ProfilePath( id: id )
    }

    public override func OnCreateViewModel( path: ProfilePath ) -> ProfileViewModel
    {
        let viewModel = ProfileViewModel()
        viewModel.Configure( id: path.id )
        return viewModel
    }
}

@Route( uri: "/settings", singleTop: .equal )
public final class SettingsRouteController: RouteController<SettingsPath, SettingsView>
{
    public override func OnCreateView( path: SettingsPath ) -> SettingsView
    {
        SettingsView( section: path.section )
    }
}

@Route( uri: "/tabs" )
public final class MainTabsRouteController: RouteController<MainTabsPath, MainTabsView>
{
}

@Route( uri: "/feed", singleTop: .equal )
public final class FeedRouteController: RouteController<FeedPath, FeedView>
{
}

@Route( uri: "/search", singleTop: .equal )
public final class SearchRouteController: RouteController<SearchPath, SearchView>
{
}

@Route( uri: "/dialog" )
public final class DialogRouteController: RouteController<DialogPath, SampleDialogView>
{
}

@Route( uri: "/sheet" )
public final class BottomSheetRouteController: RouteController<BottomSheetPath, SampleBottomSheetView>
{
}

@Route( uri: "/auth" )
public final class AuthRouteController: RouteController<AuthPath, AuthView>
{
}

public struct SampleRouterRoot: View
{
    @State
    private var router = RouterFactory.Make( registry: GeneratedRouteRegistry.Make() )

    public init()
    {
    }

    public var body: some View
    {
        RouterHost( router: router, rootPath: HomePath() )
    }
}
