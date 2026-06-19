import RouterSwiftUI

struct FlowerListPath: RoutePath, EmptyParamsPath
{
    init()
    {
    }
}

@Route( uri: "/flowers", singleTop: .equal )
final class FlowerListRouteController: RouteController<FlowerListPath, FlowerListView<FlowerListViewModelImpl>>
{
    override func OnCreateView( path: FlowerListPath ) -> FlowerListView<FlowerListViewModelImpl>
    {
        FlowerListView(
            viewModel: FlowerListViewModelImpl(
                flowerService: FlowerDependencyContainer.shared.flowerService,
                cartService: FlowerDependencyContainer.shared.cartService,
                onCartRequested: {}
            )
        )
    }
}
