//
//  RouterExampleApp.swift
//  RouterExample
//
//  Created by ALEXEY ABDULIN on 18.06.2026.
//

import SwiftUI
import RouterSwiftUI

struct NavigationBarConfig
{
    var title = ""
    var contentPlacement = RouterNavigationBarContentPlacement.inset( spacing: 16 )
    var style: TopAppBarStyle = .standard
    var actions: [TopAppBarItem] = []
}

struct NavigationBarAction
{
    var icon: Image
    var action: () -> Void
}

@MainActor
@main
struct RouterExampleApp: App
{
    @State private var router: RouterSimple
    
    init()
    {
        _router = State(
            wrappedValue: RouterFactory.Make(
                registry: GeneratedRouteRegistry.Make()
            )
        )
    }
    
    var body: some Scene
    {
        WindowGroup
        {
            RouterHost( router: router, rootPath: MainTabsPath() )
                .routerNavigationBar(
                    default: NavigationBarConfig(),
                    contentPlacement: \.contentPlacement
                )
                {
                    cfg, ctx in
                    
                    TopAppBar(
                        title: cfg.title,
                        backIcon: ctx.canGoBack ? Image( systemName: "chevron.left" ) : nil,
                        onBack: ctx.canGoBack ? ctx.back : nil,
                        logo: false,
                        style: cfg.style
                    )
                    {
                        ForEach( (0..<(cfg.actions.count)) ) { cfg.actions[$0] }
                    }
                }
        }
    }
}
