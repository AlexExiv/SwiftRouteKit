//
//  FlowerListViewModel.swift
//  SibFlowers
//
//  Created by ALEXEY ABDULIN on 17.06.2026.
//

import Combine

@MainActor
protocol FlowerListViewModel: ObservableObject
{
    associatedtype DetailVM: FlowerDetailViewModel
    
    var flowers: [Flower] { get }
    
    func Refresh()
    func MakeFlowerDetailViewModel( flower: Flower ) -> DetailVM
}

final class FlowerListViewModelStub: FlowerListViewModel
{
    @Published private(set) var flowers: [Flower]
    
    private let onCartRequested: () -> Void
    
    init( flowers: [Flower] = Flower.PresetFlowers(), onCartRequested: @escaping () -> Void = {} )
    {
        self.flowers = flowers
        self.onCartRequested = onCartRequested
    }
    
    func Refresh()
    {
        
    }
    
    func MakeFlowerDetailViewModel( flower: Flower ) -> FlowerDetailViewModelStub
    {
        return FlowerDetailViewModelStub(
            flower: flower,
            onCartRequested: onCartRequested
        )
    }
}

final class FlowerListViewModelImpl: FlowerListViewModel
{
    @Published private(set) var flowers: [Flower] = []
    
    private let flowerService: FlowerServiceProtocol
    private let cartService: CartServiceProtocol
    private let onCartRequested: () -> Void
    
    init( flowerService: FlowerServiceProtocol, cartService: CartServiceProtocol, onCartRequested: @escaping () -> Void )
    {
        self.flowerService = flowerService
        self.cartService = cartService
        self.onCartRequested = onCartRequested
        Refresh()
    }
    
    func Refresh()
    {
        flowers = flowerService.FetchFlowers()
    }
    
    func MakeFlowerDetailViewModel( flower: Flower ) -> FlowerDetailViewModelImpl
    {
        return FlowerDetailViewModelImpl(
            flower: flower,
            cartService: cartService,
            onCartRequested: onCartRequested
        )
    }
}
