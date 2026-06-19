//
//  FlowerService.swift
//  SibFlowers
//
//  Created by ALEXEY ABDULIN on 17.06.2026.
//

import Foundation

enum FlowerServiceError: LocalizedError, Equatable
{
    case emptyName
    case emptyShortDescription
    case emptyDetailedDescription
    case emptyCareTips
    
    var errorDescription: String?
    {
        switch self
        {
        case .emptyName:
            return "Введите название цветка."
            
        case .emptyShortDescription:
            return "Введите краткое описание."
            
        case .emptyDetailedDescription:
            return "Введите детальное описание."
            
        case .emptyCareTips:
            return "Введите рекомендации по уходу."
        }
    }
}

protocol FlowerServiceProtocol: AnyObject
{
    func FetchFlowers() -> [Flower]
    func FetchFlower( id: Flower.ID ) -> Flower?
    func AddFlower( name: String, shortDescription: String, detailedDescription: String, careTips: String ) throws -> Flower
}

final class FlowerService: FlowerServiceProtocol
{
    private let repository: FlowerRepositoryProtocol
    
    init( repository: FlowerRepositoryProtocol = InMemoryFlowerRepository() )
    {
        self.repository = repository
    }
    
    func FetchFlowers() -> [Flower]
    {
        return repository.FetchFlowers()
    }
    
    func FetchFlower( id: Flower.ID ) -> Flower?
    {
        return repository.FetchFlower( id: id )
    }
    
    func AddFlower( name: String, shortDescription: String, detailedDescription: String, careTips: String ) throws -> Flower
    {
        let flower = try MakeFlower(
            name: name,
            shortDescription: shortDescription,
            detailedDescription: detailedDescription,
            careTips: careTips
        )
        
        repository.Save( flower: flower )
        return flower
    }
    
    private func MakeFlower( name: String, shortDescription: String, detailedDescription: String, careTips: String ) throws -> Flower
    {
        let name = Trim( name )
        let shortDescription = Trim( shortDescription )
        let detailedDescription = Trim( detailedDescription )
        let careTips = Trim( careTips )
        
        guard !name.isEmpty else { throw FlowerServiceError.emptyName }
        guard !shortDescription.isEmpty else { throw FlowerServiceError.emptyShortDescription }
        guard !detailedDescription.isEmpty else { throw FlowerServiceError.emptyDetailedDescription }
        guard !careTips.isEmpty else { throw FlowerServiceError.emptyCareTips }
        
        return Flower(
            name: name,
            shortDescription: shortDescription,
            detailedDescription: detailedDescription,
            careTips: careTips
        )
    }
    
    private func Trim( _ value: String ) -> String
    {
        return value.trimmingCharacters( in: .whitespacesAndNewlines )
    }
}
