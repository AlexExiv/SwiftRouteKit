//
//  AddFlowerViewModel.swift
//  SibFlowers
//
//  Created by ALEXEY ABDULIN on 17.06.2026.
//

import Combine
import Foundation

@MainActor
protocol AddFlowerViewModel: ObservableObject
{
    var name: String { get set }
    var shortDescription: String { get set }
    var detailedDescription: String { get set }
    var careTips: String { get set }
    var errorMessage: String? { get }
    var canSave: Bool { get }
    
    func AddFlower() -> Bool
    func ClearError()
}

final class AddFlowerViewModelStub: AddFlowerViewModel
{
    @Published var name: String
    @Published var shortDescription: String
    @Published var detailedDescription: String
    @Published var careTips: String
    @Published private(set) var errorMessage: String?
    
    var canSave: Bool
    {
        return !Trim( name ).isEmpty &&
            !Trim( shortDescription ).isEmpty &&
            !Trim( detailedDescription ).isEmpty &&
            !Trim( careTips ).isEmpty
    }
    
    init(
        name: String = "Астра",
        shortDescription: String = "Осенний садовый цветок.",
        detailedDescription: String = "Астра хорошо цветет на солнечных участках и подходит для смешанных цветников.",
        careTips: String = "Поливать умеренно и удалять увядшие соцветия."
    )
    {
        self.name = name
        self.shortDescription = shortDescription
        self.detailedDescription = detailedDescription
        self.careTips = careTips
    }
    
    func AddFlower() -> Bool
    {
        Clear()
        return true
    }
    
    func ClearError()
    {
        errorMessage = nil
    }
    
    private func Clear()
    {
        name = ""
        shortDescription = ""
        detailedDescription = ""
        careTips = ""
        errorMessage = nil
    }
    
    private func Trim( _ value: String ) -> String
    {
        return value.trimmingCharacters( in: .whitespacesAndNewlines )
    }
}

final class AddFlowerViewModelImpl: AddFlowerViewModel
{
    @Published var name: String = ""
    @Published var shortDescription: String = ""
    @Published var detailedDescription: String = ""
    @Published var careTips: String = ""
    @Published private(set) var errorMessage: String?
    
    private let flowerService: FlowerServiceProtocol
    
    var canSave: Bool
    {
        return !Trim( name ).isEmpty &&
            !Trim( shortDescription ).isEmpty &&
            !Trim( detailedDescription ).isEmpty &&
            !Trim( careTips ).isEmpty
    }
    
    init( flowerService: FlowerServiceProtocol )
    {
        self.flowerService = flowerService
    }
    
    func AddFlower() -> Bool
    {
        do
        {
            _ = try flowerService.AddFlower(
                name: name,
                shortDescription: shortDescription,
                detailedDescription: detailedDescription,
                careTips: careTips
            )
            Clear()
            return true
        }
        catch
        {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    func ClearError()
    {
        errorMessage = nil
    }
    
    private func Clear()
    {
        name = ""
        shortDescription = ""
        detailedDescription = ""
        careTips = ""
        errorMessage = nil
    }
    
    private func Trim( _ value: String ) -> String
    {
        return value.trimmingCharacters( in: .whitespacesAndNewlines )
    }
}
