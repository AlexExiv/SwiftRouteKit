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
    associatedtype FlowerListVM: FlowerListViewModel
    associatedtype AddFlowerVM: AddFlowerViewModel
    associatedtype CartVM: CartViewModel
    
    var selectedTab: AppTab { get set }
    
    func MakeFlowerListViewModel() -> FlowerListVM
    func MakeAddFlowerViewModel() -> AddFlowerVM
    func MakeCartViewModel() -> CartVM
}

final class MainViewModelStub: MainViewModel
{
    @Published var selectedTab: AppTab = .home
    
    func MakeFlowerListViewModel() -> FlowerListViewModelStub
    {
        return FlowerListViewModelStub(
            onCartRequested:
            { [weak self] in
                self?.selectedTab = .cart
            }
        )
    }
    
    func MakeAddFlowerViewModel() -> AddFlowerViewModelStub
    {
        return AddFlowerViewModelStub()
    }
    
    func MakeCartViewModel() -> CartViewModelStub
    {
        return CartViewModelStub()
    }
}

final class MainViewModelImpl: MainViewModel
{
    @Published var selectedTab: AppTab = .home
    
    private let flowerService: FlowerServiceProtocol
    private let cartService: CartServiceProtocol
    
    init( flowerService: FlowerServiceProtocol, cartService: CartServiceProtocol )
    {
        self.flowerService = flowerService
        self.cartService = cartService
    }
    
    func MakeFlowerListViewModel() -> FlowerListViewModelImpl
    {
        return FlowerListViewModelImpl(
            flowerService: flowerService,
            cartService: cartService,
            onCartRequested: SelectCartTab
        )
    }
    
    func MakeAddFlowerViewModel() -> AddFlowerViewModelImpl
    {
        return AddFlowerViewModelImpl( flowerService: flowerService )
    }
    
    func MakeCartViewModel() -> CartViewModelImpl
    {
        return CartViewModelImpl( cartService: cartService )
    }
    
    private func SelectCartTab()
    {
        selectedTab = .cart
    }
}
