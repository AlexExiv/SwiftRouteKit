//
//  FlowerListView.swift
//  SibFlowers
//
//  Created by ALEXEY ABDULIN on 17.06.2026.
//

import SwiftUI
import RouterSwiftUI

struct FlowerListView<ViewModel: FlowerListViewModel>: RouterView
{
    @Environment( \.router ) private var router
    @StateObject private var viewModel: ViewModel
    
    init( viewModel: ViewModel )
    {
        _viewModel = StateObject( wrappedValue: viewModel )
    }
    
    var body: some View
    {
        List( viewModel.flowers ) {
            FlowerButton( $0 )
        }
        .navigationTitle( "Цветы" )
        .onAppear
        {
            viewModel.Refresh()
        }
    }

    private func FlowerButton( _ flower: Flower ) -> some View
    {
        Button
        {
            router.Route( FlowerDetailPath( flowerID: flower.id ) )
        } label:
        {
            FlowerRowView( flower: flower )
        }
        .buttonStyle( .plain )
    }
}

private struct FlowerRowView: View
{
    let flower: Flower
    
    var body: some View
    {
        VStack( alignment: .leading, spacing: 6 )
        {
            Text( flower.name )
                .font( .headline )
            
            Text( flower.shortDescription )
                .font( .subheadline )
                .foregroundStyle( .secondary )
                .lineLimit( 2 )
        }
        .padding( .vertical, 4 )
    }
}

#Preview
{
    FlowerListView( viewModel: FlowerListViewModelStub() )
}
