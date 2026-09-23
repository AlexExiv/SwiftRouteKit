import RouterSwiftUI

struct MainTabsPath: RoutePath, EmptyParamsPath
{
    init()
    {
    }
}

@Route( uri: "/" )
final class MainTabsRouteController: RouteControllerVM<MainTabsPath, MainViewModelImpl, MainTabsView<MainViewModelImpl>>
{
    override func OnCreateViewModel( path: MainTabsPath ) -> MainViewModelImpl
    {
        MainViewModelImpl(
            flowerService: FlowerDependencyContainer.shared.flowerService,
            cartService: FlowerDependencyContainer.shared.cartService
        )
    }
}
