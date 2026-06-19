//
//  FlowerDetailView.swift
//  SibFlowers
//
//  Created by ALEXEY ABDULIN on 17.06.2026.
//

import SwiftUI
import RouterSwiftUI

struct FlowerDetailView<ViewModel: FlowerDetailViewModel>: RouterView
{
    @Environment( \.router ) private var router
    @StateObject private var viewModel: ViewModel
    
    init( viewModel: ViewModel )
    {
        _viewModel = StateObject( wrappedValue: viewModel )
    }
    
    var body: some View
    {
        ScrollView
        {
            VStack( alignment: .leading, spacing: 24 )
            {
                VStack( alignment: .leading, spacing: 8 )
                {
                    Text( viewModel.flower.name )
                        .font( .largeTitle )
                        .fontWeight( .bold )
                    
                    Text( viewModel.flower.shortDescription )
                        .font( .title3 )
                        .foregroundStyle( .secondary )
                }
                
                DetailBlockView(
                    title: "Описание",
                    systemImage: "text.alignleft",
                    text: viewModel.flower.detailedDescription
                )
                
                DetailBlockView(
                    title: "Уход",
                    systemImage: "drop.fill",
                    text: viewModel.flower.careTips
                )
            }
            .frame( maxWidth: .infinity, alignment: .leading )
            .padding()
        }
        .navigationTitle( viewModel.flower.name )
        .navigationBarTitleDisplayMode( .inline )
        .safeAreaInset( edge: .bottom )
        {
            Button
            {
                if viewModel.isInCart
                {
                    router.Route( CartPath() )
                }
                else
                {
                    viewModel.AddToCart()
                }
            } label:
            {
                Label( viewModel.isInCart ? "Открыть корзину" : "В корзину", systemImage: "basket.fill" )
                    .font( .headline )
                    .frame( maxWidth: .infinity )
            }
            .buttonStyle( .borderedProminent )
            .controlSize( .large )
            .padding()
            .background( .bar )
        }
    }
}

private struct DetailBlockView: View
{
    let title: String
    let systemImage: String
    let text: String
    
    var body: some View
    {
        VStack( alignment: .leading, spacing: 10 )
        {
            Label( title, systemImage: systemImage )
                .font( .headline )
            
            Text( text )
                .font( .body )
                .foregroundStyle( .primary )
                .fixedSize( horizontal: false, vertical: true )
        }
    }
}

#Preview
{
    FlowerDetailView( viewModel: FlowerDetailViewModelStub() )
}
