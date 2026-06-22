import Foundation
import RouterSwiftUI

struct FlowerDetailPath: RoutePath
{
    let flowerID: Flower.ID
    
    init( flowerID: Flower.ID )
    {
        self.flowerID = flowerID
    }
}

@Route( uri: "/flowers/:id" )
final class FlowerDetailRouteController: RouteController<FlowerDetailPath, FlowerDetailView<FlowerDetailViewModelImpl>>
{
    override func Convert( path: [String: String], query: [String: String] ) -> FlowerDetailPath?
    {
        guard let rawID = path["id"], let flowerID = UUID( uuidString: rawID ) else { return nil }
        
        return FlowerDetailPath( flowerID: flowerID )
    }
    
    override func OnCreateView( path: FlowerDetailPath ) -> FlowerDetailView<FlowerDetailViewModelImpl>
    {
        FlowerDetailView(
            viewModel: FlowerDetailViewModelImpl(
                flower: FlowerDependencyContainer.shared.flowerService.FetchFlower( id: path.flowerID ) ?? Flower.MissingFlower( id: path.flowerID ),
                cartService: FlowerDependencyContainer.shared.cartService,
                onCartRequested: {}
            )
        )
    }
}
