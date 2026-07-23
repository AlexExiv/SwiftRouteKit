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
    let authService: AuthServiceProtocol
    
    init(
        flowerService: FlowerServiceProtocol = FlowerService(),
        cartService: CartServiceProtocol = CartService(),
        authService: AuthServiceProtocol = AuthService()
    )
    {
        self.flowerService = flowerService
        self.cartService = cartService
        self.authService = authService
    }
}
