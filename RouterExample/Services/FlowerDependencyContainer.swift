//
//  FlowerDependencyContainer.swift
//  SibFlowers
//
//  Created by ALEXEY ABDULIN on 17.06.2026.
//

import Combine

final class FlowerDependencyContainer: ObservableObject
{
    static let shared = FlowerDependencyContainer()
    
    let flowerService: FlowerServiceProtocol
    let cartService: CartServiceProtocol
    
    init( flowerService: FlowerServiceProtocol = FlowerService(), cartService: CartServiceProtocol = CartService() )
    {
        self.flowerService = flowerService
        self.cartService = cartService
    }
}
