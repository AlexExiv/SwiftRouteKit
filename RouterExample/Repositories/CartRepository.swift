//
//  CartRepository.swift
//  SibFlowers
//
//  Created by ALEXEY ABDULIN on 17.06.2026.
//

import Foundation

protocol CartRepositoryProtocol: AnyObject
{
    func FetchItems() -> [CartItem]
    func FetchItem( flowerID: Flower.ID ) -> CartItem?
    func Save( item: CartItem )
    func Remove( flowerID: Flower.ID )
}

final class InMemoryCartRepository: CartRepositoryProtocol
{
    private var items: [CartItem]
    
    init( items: [CartItem] = [] )
    {
        self.items = items
    }
    
    func FetchItems() -> [CartItem]
    {
        return items
    }
    
    func FetchItem( flowerID: Flower.ID ) -> CartItem?
    {
        return items.first { $0.flower.id == flowerID }
    }
    
    func Save( item: CartItem )
    {
        if let index = items.firstIndex( where: { $0.flower.id == item.flower.id } )
        {
            items[index] = item
        }
        else
        {
            items.append( item )
        }
    }
    
    func Remove( flowerID: Flower.ID )
    {
        items.removeAll { $0.flower.id == flowerID }
    }
}
