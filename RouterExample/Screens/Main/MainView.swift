//
//  MainView.swift
//  SibFlowers
//
//  Created by ALEXEY ABDULIN on 17.06.2026.
//

import SwiftUI
import RouterSwiftUI

struct MainTabsView: RouterTabsView
{
    var body: some View
    {
        RouterTabsHost(
            descriptors: [
                RouterTabDescriptor(
                    id: "home",
                    index: 0,
                    title: "Главная",
                    systemImage: "house.fill",
                    rootPath: HomePath()
                ),
                RouterTabDescriptor(
                    id: "cart",
                    index: 1,
                    title: "Корзина",
                    systemImage: "basket.fill",
                    rootPath: CartPath()
                )
            ]
        )
    }
}

struct HomeView: RouterView
{
    @Environment( \.router ) private var router
    
    var body: some View
    {
        List
        {
            Section
            {
                Button
                {
                    router.Route( FlowerListPath() )
                } label:
                {
                    MainMenuRow(
                        title: "Список цветов",
                        subtitle: "Каталог растений с кратким и детальным описанием.",
                        systemImage: "leaf.fill",
                        tint: .green
                    )
                }
                
                Button
                {
                    router.Route( AddFlowerPath() )
                } label:
                {
                    MainMenuRow(
                        title: "Добавить цветок",
                        subtitle: "Форма для создания нового растения в каталоге.",
                        systemImage: "plus.circle.fill",
                        tint: .blue
                    )
                }
            }
        }
        .buttonStyle( .plain )
        .navigationTitle( "SibFlowers" )
    }
}

private struct MainMenuRow: View
{
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    
    var body: some View
    {
        HStack( spacing: 14 )
        {
            Image( systemName: systemImage )
                .font( .title2 )
                .foregroundStyle( tint )
                .frame( width: 32, height: 32 )
            
            VStack( alignment: .leading, spacing: 4 )
            {
                Text( title )
                    .font( .headline )
                    .foregroundStyle( .primary )
                
                Text( subtitle )
                    .font( .subheadline )
                    .foregroundStyle( .secondary )
                    .fixedSize( horizontal: false, vertical: true )
            }
        }
        .padding( .vertical, 6 )
        .contentShape( Rectangle() )
    }
}

#Preview
{
    HomeView()
}
