import Combine
import SwiftUI

#if os(iOS)
import UIKit
#endif

public struct RouterTabsHost<Label: View>: View
{
    @Environment( \.router )
    private var router

    @Environment( \.routeEntry )
    private var routeEntry

    @StateObject
    private var state = RouterTabsHostState()

    private let descriptors: [RouterTabDescriptor]
    private let tabRouteInParent: Bool
    private let backToFirst: Bool
    private let tabUnique: RouteTabUnique
    private let label: (RouterTabDescriptor) -> Label

    public init( descriptors: [RouterTabDescriptor], tabRouteInParent: Bool = false, backToFirst: Bool = true, tabUnique: RouteTabUnique = .class, @ViewBuilder label: @escaping ( RouterTabDescriptor ) -> Label )
    {
        self.descriptors = descriptors
        self.tabRouteInParent = tabRouteInParent
        self.backToFirst = backToFirst
        self.tabUnique = tabUnique
        self.label = label
    }

    public var body: some View
    {
        Group {
            if let tabs = state.tabs
            {
                #if os(iOS)
                ZStack( alignment: .bottom )
                {
                    TabsContent( tabs )

                    RouterSystemTabBar(
                        descriptors: descriptors,
                        selectedIndex: state.selectedTab
                    ) {
                        tabs.Route( $0 )
                    }
                    .frame(
                        width: CGFloat( descriptors.count ) * 112,
                        height: 72
                    )
                    .padding( .bottom, -6 )
                }
                #else
                TabsContent( tabs )
                #endif
            }
            else
            {
                Color.clear
            }
        }
        .onAppear {
            guard let router = router as? RouterSimple, let routeEntry else { return }

            let tabs = router.CreateTabs( viewKey: routeEntry.id, descriptors: descriptors, tabRouteInParent: tabRouteInParent, backToFirst: backToFirst, tabUnique: tabUnique )

            for descriptor in descriptors
            {
                tabs.Route( descriptor.index, path: descriptor.rootPath, recreate: false )
            }

            state.Bind( tabs )
        }
        .onDisappear {
            state.Unbind()
        }
    }

    private func TabContent( _ descriptor: RouterTabDescriptor, tabs: RouterTabs ) -> some View
    {
        #if os(iOS)
        AnyRouterHost( router: tabs.Router( for: descriptor ), rootPath: descriptor.rootPath )
        #else
        AnyRouterHost( router: tabs.Router( for: descriptor ), rootPath: descriptor.rootPath )
            .tabItem { label( descriptor ) }
            .tag( descriptor.index )
        #endif
    }

    private func TabsContent( _ tabs: RouterTabs ) -> some View
    {
        #if os(iOS)
        ZStack
        {
            ForEach( descriptors ) { descriptor in
                TabContent( descriptor, tabs: tabs )
                    .opacity( state.selectedTab == descriptor.index ? 1 : 0 )
                    .allowsHitTesting( state.selectedTab == descriptor.index )
                    .accessibilityHidden( state.selectedTab != descriptor.index )
            }
        }
        .frame( maxWidth: .infinity, maxHeight: .infinity )
        #else
        TabView( selection: Binding(
            get: { state.selectedTab },
            set: { _ in } ) ) {
            ForEach( descriptors ) {
                TabContent( $0, tabs: tabs )
            }
        }
        #endif
    }
}

@MainActor
private final class RouterTabsHostState: ObservableObject
{
    @Published
    var tabs: RouterTabs?

    @Published
    var selectedTab = 0

    func Bind( _ tabs: RouterTabs )
    {
        if self.tabs !== tabs
        {
            self.tabs?.tabChangeCallback = nil
        }

        selectedTab = tabs.tabIndex
        tabs.tabChangeCallback = { [weak self] in self?.selectedTab = $0 }
        self.tabs = tabs
    }

    func Unbind()
    {
        tabs?.tabChangeCallback = nil
    }
}

#if os(iOS)
private struct RouterSystemTabBar: UIViewRepresentable
{
    let descriptors: [RouterTabDescriptor]
    let selectedIndex: Int
    let route: (Int) -> Bool

    func makeCoordinator() -> Coordinator
    {
        Coordinator()
    }

    func makeUIView( context: Context ) -> UITabBar
    {
        let tabBar = UITabBar()
        tabBar.delegate = context.coordinator
        tabBar.isTranslucent = true
        tabBar.backgroundColor = .clear

        Configure( tabBar )
        return tabBar
    }

    func updateUIView( _ tabBar: UITabBar, context: Context )
    {
        context.coordinator.route = route
        context.coordinator.selectedIndex = selectedIndex
        Configure( tabBar )
    }

    private func Configure( _ tabBar: UITabBar )
    {
        let currentTags = tabBar.items?.map( \.tag ) ?? []
        let nextTags = descriptors.map( \.index )

        if currentTags != nextTags
        {
            let items = descriptors.map {
                let item = UITabBarItem(
                    title: $0.title,
                    image: UIImage( named: $0.systemImage ?? "" ) ?? UIImage( systemName: $0.systemImage ?? "circle" ),
                    tag: $0.index
                )
                return item
            }

            tabBar.setItems( items, animated: false )
        }

        tabBar.selectedItem = tabBar.items?.first { $0.tag == selectedIndex }
    }

    final class Coordinator: NSObject, UITabBarDelegate
    {
        var route: ((Int) -> Bool)?
        var selectedIndex = 0

        func tabBar( _ tabBar: UITabBar, didSelect item: UITabBarItem )
        {
            if route?( item.tag ) != true
            {
                DispatchQueue.main.async { [weak tabBar, selectedIndex] in
                    tabBar?.selectedItem = tabBar?.items?.first { $0.tag == selectedIndex }
                }
                return
            }
        }
    }
}
#endif

public extension RouterTabsHost where Label == SwiftUI.Label<Text, Image>
{
    init( descriptors: [RouterTabDescriptor], tabRouteInParent: Bool = false, backToFirst: Bool = true, tabUnique: RouteTabUnique = .class )
    {
        self.init( descriptors: descriptors, tabRouteInParent: tabRouteInParent, backToFirst: backToFirst, tabUnique: tabUnique ) {
                Label( $0.title, systemImage: $0.systemImage ?? "circle" )
            }
    }
}
