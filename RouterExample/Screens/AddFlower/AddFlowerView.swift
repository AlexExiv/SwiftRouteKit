//
//  AddFlowerView.swift
//  SibFlowers
//
//  Created by ALEXEY ABDULIN on 17.06.2026.
//

import SwiftUI
import RouterSwiftUI

struct AddFlowerView<ViewModel: AddFlowerViewModel>: RouterView
{
    @Environment( \.router ) private var router
    @StateObject private var viewModel: ViewModel
    
    init( viewModel: ViewModel )
    {
        _viewModel = StateObject( wrappedValue: viewModel )
    }
    
    var body: some View
    {
        Form
        {
            Section( "Основное" )
            {
                TextField( "Название", text: $viewModel.name )
                TextField( "Краткое описание", text: $viewModel.shortDescription, axis: .vertical )
                    .lineLimit( 2...4 )
            }
            
            Section( "Детальное описание" )
            {
                TextEditor( text: $viewModel.detailedDescription )
                    .frame( minHeight: 120 )
            }
            
            Section( "Уход" )
            {
                TextEditor( text: $viewModel.careTips )
                    .frame( minHeight: 100 )
            }
        }
        .navigationTitle( "Новый цветок" )
        .toolbar
        {
            ToolbarItem( placement: .confirmationAction )
            {
                Button
                {
                    Save()
                } label:
                {
                    Label( "Сохранить", systemImage: "checkmark" )
                }
                .disabled( !viewModel.canSave )
            }
        }
        .alert(
            "Не удалось сохранить",
            isPresented: Binding(
                get:
                {
                    viewModel.errorMessage != nil
                },
                set:
                {
                    if !$0
                    {
                        viewModel.ClearError()
                    }
                }
            )
        )
        {
            Button( "OK", role: .cancel )
            {
                viewModel.ClearError()
            }
        } message:
        {
            Text( viewModel.errorMessage ?? "" )
        }
    }
    
    private func Save()
    {
        if viewModel.AddFlower()
        {
            router.Close()
        }
    }
}

#Preview
{
    AddFlowerView( viewModel: AddFlowerViewModelStub() )
}
