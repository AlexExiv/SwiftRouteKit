import Combine
import SwiftUI

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
    private let label: ( RouterTabDescriptor ) -> Label

    public init(
        descriptors: [RouterTabDescriptor],
        tabRouteInParent: Bool = false,
        backToFirst: Bool = true,
        tabUnique: RouteTabUnique = .class,
        @ViewBuilder label: @escaping ( RouterTabDescriptor ) -> Label )
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
                TabView( selection: Binding(
                    get: { tabs.tabIndex },
                    set: { _ = tabs.Route( $0 ) } ) ) {
                    ForEach( descriptors ) {
                        TabContent( $0, tabs: tabs )
                    }
                }
            }
            else
            {
                Color.clear
            }
        }
        .onAppear {
            guard let router = router as? RouterSimple, let routeEntry else { return }

            state.tabs = router.CreateTabs(
                viewKey: routeEntry.id,
                descriptors: descriptors,
                tabRouteInParent: tabRouteInParent,
                backToFirst: backToFirst,
                tabUnique: tabUnique )
        }
    }

    private func TabContent( _ descriptor: RouterTabDescriptor, tabs: RouterTabs ) -> some View
    {
        AnyRouterHost(
            router: tabs.Router( for: descriptor ),
            rootPath: descriptor.rootPath )
            .tabItem { label( descriptor ) }
            .tag( descriptor.index )
    }
}

@MainActor
private final class RouterTabsHostState: ObservableObject
{
    @Published
    var tabs: RouterTabs?
}

public extension RouterTabsHost where Label == SwiftUI.Label<Text, Image>
{
    init(
        descriptors: [RouterTabDescriptor],
        tabRouteInParent: Bool = false,
        backToFirst: Bool = true,
        tabUnique: RouteTabUnique = .class )
    {
        self.init(
            descriptors: descriptors,
            tabRouteInParent: tabRouteInParent,
            backToFirst: backToFirst,
            tabUnique: tabUnique ) {
                Label(
                    $0.title,
                    systemImage: $0.systemImage ?? "circle" )
            }
    }
}
