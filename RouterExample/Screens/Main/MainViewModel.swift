//
//  MainViewModel.swift
//  SibFlowers
//
//  Created by ALEXEY ABDULIN on 17.06.2026.
//

import Combine
import RouterSwiftUI

@MainActor
protocol MainViewModel: ObservableObject
{
    var inCartCount: Int { get }
}

final class MainViewModelStub: MainViewModel
{
    @Published
    private(set) var inCartCount = 0
}

final class MainViewModelImpl: RouterViewModel, MainViewModel
{
    private let flowerService: FlowerServiceProtocol
    private let cartService: CartServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    @Published
    private(set) var inCartCount = 0
    
    init( flowerService: FlowerServiceProtocol, cartService: CartServiceProtocol )
    {
        self.flowerService = flowerService
        self.cartService = cartService
        
        super.init()

        cartService
            .itemsPublisher
            .map { $0.reduce( 0 ) { $0 + $1.quantity } }
            .sink { [weak self] in self?.inCartCount = $0 }
            .store( in: &cancellables )
    }
}
