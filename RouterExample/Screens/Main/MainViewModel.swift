//
//  MainViewModel.swift
//  SibFlowers
//
//  Created by ALEXEY ABDULIN on 17.06.2026.
//

import Combine

@MainActor
protocol MainViewModel: ObservableObject
{

}

final class MainViewModelStub: MainViewModel
{

}

final class MainViewModelImpl: MainViewModel
{
    private let flowerService: FlowerServiceProtocol
    private let cartService: CartServiceProtocol
    
    init( flowerService: FlowerServiceProtocol, cartService: CartServiceProtocol )
    {
        self.flowerService = flowerService
        self.cartService = cartService
    }
}
