//
//  CartViewModel.swift
//  SibFlowers
//
//  Created by ALEXEY ABDULIN on 17.06.2026.
//

import Combine

@MainActor
protocol CartViewModel: ObservableObject
{
    var items: [CartItem] { get }
    
    func Increase( item: CartItem )
    func Decrease( item: CartItem )
}

final class CartViewModelStub: CartViewModel
{
    @Published private(set) var items: [CartItem]
    
    init(
        items: [CartItem] = [
            CartItem(
                flower: Flower.PresetFlowers()[0],
                quantity: 2
            ),
            CartItem(
                flower: Flower.PresetFlowers()[1],
                quantity: 1
            )
        ]
    )
    {
        self.items = items
    }
    
    func Increase( item: CartItem )
    {
        SetQuantity(
            item: item,
            quantity: item.quantity + 1
        )
    }
    
    func Decrease( item: CartItem )
    {
        SetQuantity(
            item: item,
            quantity: item.quantity - 1
        )
    }
    
    private func SetQuantity( item: CartItem, quantity: Int )
    {
        if quantity <= 0
        {
            items.removeAll { $0.id == item.id }
        }
        else if let index = items.firstIndex( where: { $0.id == item.id } )
        {
            items[index] = CartItem(
                flower: item.flower,
                quantity: quantity
            )
        }
    }
}

final class CartViewModelImpl: CartViewModel
{
    @Published private(set) var items: [CartItem] = []
    
    private let cartService: CartServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init( cartService: CartServiceProtocol )
    {
        self.cartService = cartService
        self.items = cartService.FetchItems()
        
        cartService
            .itemsPublisher
            .sink
            { [weak self] items in
                self?.items = items
            }
            .store( in: &cancellables )
    }
    
    func Increase( item: CartItem )
    {
        cartService.Increase( flower: item.flower )
    }
    
    func Decrease( item: CartItem )
    {
        cartService.Decrease( flower: item.flower )
    }
}
