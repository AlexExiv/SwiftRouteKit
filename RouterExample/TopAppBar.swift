//
//  TopAppBar.swift
//  RouterExample
//
//  Created by ALEXEY ABDULIN on 16.07.2026.
//

import SwiftUI
import RouterSwiftUI

enum TopAppBarStyle
{
    case standard
    case transparent

    var containerColor: Color
    {
        switch self
        {
        case .standard: .green
        case .transparent: .clear
        }
    }

    var titleColor: Color
    {
        switch self
        {
        case .standard: .black
        case .transparent: .clear
        }
    }
}

struct TopAppBarItem: View
{
    let icon: Image
    let action: () -> Void

    var body: some View
    {
        Button( action: action )
        {
            icon
                .resizable()
                .scaledToFit()
                .frame( width: 19, height: 19 )
                .foregroundStyle( .blue )
                .frame( width: 38, height: 38 )
                .background(
                    Circle()
                        .fill( .yellow )
                )
        }
        .buttonStyle( .plain )
    }
}

struct TopAppBar<Actions: View>: View
{
    var title: String = ""
    var backIcon: Image? = Image( systemName: "icon.back" )
    var onBack: (() -> Void)? = nil
    var logo: Bool = false
    var style: TopAppBarStyle = .standard
    @ViewBuilder var actions: () -> Actions

    var body: some View
    {
        ZStack
        {
            HStack( spacing: 8 )
            {
                if let backIcon
                {
                    TopAppBarItem( icon: backIcon, action: { onBack?() } )
                }

                Spacer( minLength: 0 )

                HStack( spacing: 8 )
                {
                    actions()
                }
            }

            if !logo, !title.isEmpty
            {
                Text( title )
                    .font( .system( size: 17, weight: .bold ) )
                    .foregroundStyle( style.titleColor )
                    .lineLimit( 1 )
                    .padding( .horizontal, 48 )
            }
        }
        .padding( .horizontal, 16.0 )
        .frame( height: 44 )
        .frame( maxWidth: .infinity )
        .background( style.containerColor )
    }
}

extension View
{
    func topAppBarTitle( _ title: String ) -> some View
    {
        routerNavigationBar(
            update:
            {
                (cfg: inout NavigationBarConfig) in
                
                cfg.title = title
            }
        )
    }
}
