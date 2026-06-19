import RouterSwiftUI

struct AddFlowerPath: RoutePath, EmptyParamsPath
{
    init()
    {
    }
}

@Route( uri: "/flowers/new", singleTop: .equal )
final class AddFlowerRouteController: RouteController<AddFlowerPath, AddFlowerView<AddFlowerViewModelImpl>>
{
    override func OnCreateView( path: AddFlowerPath ) -> AddFlowerView<AddFlowerViewModelImpl>
    {
        AddFlowerView(
            viewModel: AddFlowerViewModelImpl(
                flowerService: FlowerDependencyContainer.shared.flowerService
            )
        )
    }
}
