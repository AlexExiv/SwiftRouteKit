//
//  FlowerRepository.swift
//  SibFlowers
//
//  Created by ALEXEY ABDULIN on 17.06.2026.
//

import Foundation

protocol FlowerRepositoryProtocol: AnyObject
{
    func FetchFlowers() -> [Flower]
    func FetchFlower( id: Flower.ID ) -> Flower?
    func Save( flower: Flower )
}

final class InMemoryFlowerRepository: FlowerRepositoryProtocol
{
    private var flowers: [Flower]
    
    init( flowers: [Flower] = Flower.PresetFlowers() )
    {
        self.flowers = flowers
    }
    
    func FetchFlowers() -> [Flower]
    {
        return flowers
    }
    
    func FetchFlower( id: Flower.ID ) -> Flower?
    {
        return flowers.first { $0.id == id }
    }
    
    func Save( flower: Flower )
    {
        flowers.append( flower )
    }
}
