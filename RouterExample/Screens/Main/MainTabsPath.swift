import RouterSwiftUI

struct MainTabsPath: RoutePath, EmptyParamsPath
{
    init()
    {
    }
}

@Route( uri: "/" )
final class MainTabsRouteController: RouteController<MainTabsPath, MainTabsView>
{
    override func OnCreateView( path: MainTabsPath ) -> MainTabsView
    {
        MainTabsView()
    }
}
