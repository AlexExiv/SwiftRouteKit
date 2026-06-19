//
//  FlowerDetailViewModel.swift
//  SibFlowers
//
//  Created by ALEXEY ABDULIN on 17.06.2026.
//

import Combine

@MainActor
protocol FlowerDetailViewModel: ObservableObject
{
    var flower: Flower { get }
    var isInCart: Bool { get }
    
    func AddToCart()
}

final class FlowerDetailViewModelStub: FlowerDetailViewModel
{
    @Published private(set) var isInCart: Bool
    
    let flower: Flower
    private let onCartRequested: () -> Void
    
    init( flower: Flower = Flower.PresetFlowers()[0], isInCart: Bool = false, onCartRequested: @escaping () -> Void = {} )
    {
        self.flower = flower
        self.isInCart = isInCart
        self.onCartRequested = onCartRequested
    }
    
    func AddToCart()
    {
        if isInCart
        {
            onCartRequested()
        }
        else
        {
            isInCart = true
        }
    }
}

final class FlowerDetailViewModelImpl: FlowerDetailViewModel
{
    @Published private(set) var isInCart: Bool = false
    
    let flower: Flower
    private let cartService: CartServiceProtocol
    private let onCartRequested: () -> Void
    private var cancellables = Set<AnyCancellable>()
    
    init( flower: Flower, cartService: CartServiceProtocol, onCartRequested: @escaping () -> Void )
    {
        self.flower = flower
        self.cartService = cartService
        self.onCartRequested = onCartRequested
        UpdateCartState()
        
        cartService
            .itemsPublisher
            .sink
            { [weak self] _ in
                self?.UpdateCartState()
            }
            .store( in: &cancellables )
    }
    
    func AddToCart()
    {
        if isInCart
        {
            onCartRequested()
        }
        else
        {
            cartService.Add( flower: flower )
        }
    }
    
    private func UpdateCartState()
    {
        isInCart = cartService.Contains( flowerID: flower.id )
    }
}
