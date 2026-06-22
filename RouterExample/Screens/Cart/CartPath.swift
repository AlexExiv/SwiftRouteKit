import RouterSwiftUI

struct CartPath: RoutePath, EmptyParamsPath
{
    init()
    {
    }
}

@Route( uri: "/cart", singleTop: .class )
final class CartRouteController: RouteController<CartPath, CartView<CartViewModelImpl>>
{
    override func OnCreateView( path: CartPath ) -> CartView<CartViewModelImpl>
    {
        CartView(
            viewModel: CartViewModelImpl(
                cartService: FlowerDependencyContainer.shared.cartService
            )
        )
    }
}
