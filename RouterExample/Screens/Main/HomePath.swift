import RouterSwiftUI

struct HomePath: RoutePath, EmptyParamsPath
{
    init()
    {
    }
}

@Route( uri: "/home", singleTop: .equal )
final class HomeRouteController: RouteController<HomePath, HomeView>
{
    override func OnCreateView( path: HomePath ) -> HomeView
    {
        HomeView()
    }
}
