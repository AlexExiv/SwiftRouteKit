//
//  CartView.swift
//  SibFlowers
//
//  Created by ALEXEY ABDULIN on 17.06.2026.
//

import SwiftUI
import RouterSwiftUI

struct CartView<ViewModel: CartViewModel>: RouterView
{
    @StateObject private var viewModel: ViewModel
    
    init( viewModel: ViewModel )
    {
        _viewModel = StateObject( wrappedValue: viewModel )
    }
    
    var body: some View
    {
        Group
        {
            if viewModel.items.isEmpty
            {
                EmptyCartView()
            }
            else
            {
                List( viewModel.items ) {
                    ItemRow( $0 )
                }
            }
        }
        .navigationTitle( "Корзина" )
    }

    private func ItemRow( _ item: CartItem ) -> some View
    {
        CartItemRowView(
            item: item,
            onIncrease:
            {
                viewModel.Increase( item: item )
            },
            onDecrease:
            {
                viewModel.Decrease( item: item )
            }
        )
    }
}

private struct EmptyCartView: View
{
    var body: some View
    {
        VStack( spacing: 12 )
        {
            Image( systemName: "basket" )
                .font( .system( size: 44 ) )
                .foregroundStyle( .secondary )
            
            Text( "Корзина пуста" )
                .font( .headline )
            
            Text( "Добавленные цветы появятся здесь." )
                .font( .subheadline )
                .foregroundStyle( .secondary )
                .multilineTextAlignment( .center )
        }
        .frame( maxWidth: .infinity, maxHeight: .infinity )
        .padding()
    }
}

private struct CartItemRowView: View
{
    let item: CartItem
    let onIncrease: () -> Void
    let onDecrease: () -> Void
    
    var body: some View
    {
        HStack( alignment: .center, spacing: 12 )
        {
            VStack( alignment: .leading, spacing: 6 )
            {
                Text( item.flower.name )
                    .font( .headline )
                
                Text( item.flower.shortDescription )
                    .font( .subheadline )
                    .foregroundStyle( .secondary )
                    .lineLimit( 2 )
            }
            
            Spacer( minLength: 8 )
            
            HStack( spacing: 10 )
            {
                Button
                {
                    onDecrease()
                } label:
                {
                    Image( systemName: "minus.circle.fill" )
                        .font( .title3 )
                }
                .buttonStyle( .borderless )
                
                Text( "\(item.quantity)" )
                    .font( .headline )
                    .monospacedDigit()
                    .frame( minWidth: 24 )
                
                Button
                {
                    onIncrease()
                } label:
                {
                    Image( systemName: "plus.circle.fill" )
                        .font( .title3 )
                }
                .buttonStyle( .borderless )
            }
        }
        .padding( .vertical, 4 )
    }
}

#Preview
{
    CartView( viewModel: CartViewModelStub() )
}
