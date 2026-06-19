//
//  CartService.swift
//  SibFlowers
//
//  Created by ALEXEY ABDULIN on 17.06.2026.
//

import Combine
import Foundation

protocol CartServiceProtocol: AnyObject
{
    var itemsPublisher: AnyPublisher<[CartItem], Never> { get }
    
    func FetchItems() -> [CartItem]
    func Quantity( flowerID: Flower.ID ) -> Int
    func Contains( flowerID: Flower.ID ) -> Bool
    func Add( flower: Flower )
    func Increase( flower: Flower )
    func Decrease( flower: Flower )
}

final class CartService: CartServiceProtocol
{
    private let repository: CartRepositoryProtocol
    private let itemsSubject: CurrentValueSubject<[CartItem], Never>
    
    var itemsPublisher: AnyPublisher<[CartItem], Never>
    {
        return itemsSubject.eraseToAnyPublisher()
    }
    
    init( repository: CartRepositoryProtocol = InMemoryCartRepository() )
    {
        self.repository = repository
        self.itemsSubject = CurrentValueSubject( repository.FetchItems() )
    }
    
    func FetchItems() -> [CartItem]
    {
        return repository.FetchItems()
    }
    
    func Quantity( flowerID: Flower.ID ) -> Int
    {
        return repository.FetchItem( flowerID: flowerID )?.quantity ?? 0
    }
    
    func Contains( flowerID: Flower.ID ) -> Bool
    {
        return Quantity( flowerID: flowerID ) > 0
    }
    
    func Add( flower: Flower )
    {
        guard !Contains( flowerID: flower.id ) else { return }
        
        repository.Save(
            item: CartItem(
                flower: flower,
                quantity: 1
            )
        )
        PublishItems()
    }
    
    func Increase( flower: Flower )
    {
        SetQuantity(
            flower: flower,
            quantity: Quantity( flowerID: flower.id ) + 1
        )
    }
    
    func Decrease( flower: Flower )
    {
        SetQuantity(
            flower: flower,
            quantity: Quantity( flowerID: flower.id ) - 1
        )
    }
    
    private func SetQuantity( flower: Flower, quantity: Int )
    {
        if quantity <= 0
        {
            repository.Remove( flowerID: flower.id )
        }
        else
        {
            repository.Save(
                item: CartItem(
                    flower: flower,
                    quantity: quantity
                )
            )
        }
        
        PublishItems()
    }
    
    private func PublishItems()
    {
        itemsSubject.send( repository.FetchItems() )
    }
}
