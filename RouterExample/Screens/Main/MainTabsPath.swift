import RouterSwiftUI

struct MainTabsPath: RoutePath, EmptyParamsPath
{
    init()
    {
    }
}

@Route( uri: "/", singleTop: .equal )
final class MainTabsRouteController: RouteController<MainTabsPath, MainTabsView>
{
    override func OnCreateView( path: MainTabsPath ) -> MainTabsView
    {
        MainTabsView()
    }
}
