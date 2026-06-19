//
//  RouterExampleApp.swift
//  RouterExample
//
//  Created by ALEXEY ABDULIN on 18.06.2026.
//

import SwiftUI
import RouterSwiftUI

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
        }
    }
}
