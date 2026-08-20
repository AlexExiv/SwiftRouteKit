import SwiftUI
import RouterSwiftUI

struct Tab2Path: RoutePath, EmptyParamsPath
{
    init()
    {
    }
}

@Route( uri: "/tab2", singleTop: .class )
final class Tab2RouteController: RouteController<Tab2Path, Tab2View>
{
    override func OnCreateView( path: Tab2Path ) -> Tab2View
    {
        Tab2View()
    }
}

struct Tab2View: RouterView
{
    var body: some View
    {
        TestTabView( title: "Tab 2" )
    }
}

struct Tab3Path: RoutePath, EmptyParamsPath
{
    init()
    {
    }
}

@Route( uri: "/tab3", singleTop: .class )
final class Tab3RouteController: RouteController<Tab3Path, Tab3View>
{
    override func OnCreateView( path: Tab3Path ) -> Tab3View
    {
        Tab3View()
    }
}

struct Tab3View: RouterView
{
    var body: some View
    {
        TestTabView( title: "Tab 3" )
    }
}

struct Tab4Path: RoutePath, EmptyParamsPath
{
    init()
    {
    }
}

@Route( uri: "/tab4", singleTop: .class )
final class Tab4RouteController: RouteController<Tab4Path, Tab4View>
{
    override func OnCreateView( path: Tab4Path ) -> Tab4View
    {
        Tab4View()
    }
}

struct Tab4View: RouterView
{
    var body: some View
    {
        TestTabView( title: "Tab 4" )
    }
}

private struct TestTabView: RouterView
{
    let title: String

    var body: some View
    {
        VStack( spacing: 12 )
        {
            Image( systemName: "rectangle.grid.1x2" )
                .font( .system( size: 44 ) )
                .foregroundStyle( .secondary )

            Text( title )
                .font( .title2 )
                .fontWeight( .semibold )
        }
        .frame( maxWidth: .infinity, maxHeight: .infinity )
        .topAppBarTitle( title )
    }
}
