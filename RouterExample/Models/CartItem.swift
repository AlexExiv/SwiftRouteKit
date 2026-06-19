//
//  CartItem.swift
//  SibFlowers
//
//  Created by ALEXEY ABDULIN on 17.06.2026.
//

import Foundation

struct CartItem: Identifiable, Hashable
{
    let flower: Flower
    var quantity: Int
    
    var id: UUID
    {
        return flower.id
    }
}
