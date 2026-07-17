import Combine
import SwiftUI

public enum RouterNavigationBarContentPlacement: Equatable
{
    case inset( spacing: CGFloat )
    case overlay
}

@MainActor
public struct RouterNavigationBarContext
{
    public let entry: RouteEntry
    public let canGoBack: Bool
    public let back: () -> Void

    init( entry: RouteEntry, canGoBack: Bool, back: @escaping () -> Void )
    {
        self.entry = entry
        self.canGoBack = canGoBack
        self.back = back
    }
}

@MainActor
struct AnyRouterNavigationBarProvider
{
    let configurationType: ObjectIdentifier
    let defaultConfiguration: Any
    let makeView: ( Any, RouterNavigationBarContext ) -> AnyView
    let contentPlacement: ( Any ) -> RouterNavigationBarContentPlacement

    init<Configuration, Bar: View>( configuration: Configuration, @ViewBuilder content: @escaping ( Configuration, RouterNavigationBarContext ) -> Bar )
    {
        self.init( configuration: configuration, contentPlacement: { _ in .inset( spacing: 0 ) }, content: content )
    }

    init<Configuration, Bar: View>( configuration: Configuration, contentSpacing: @escaping ( Configuration ) -> CGFloat, @ViewBuilder content: @escaping ( Configuration, RouterNavigationBarContext ) -> Bar )
    {
        self.init(
            configuration: configuration,
            contentPlacement: { .inset( spacing: contentSpacing( $0 ) ) },
            content: content )
    }

    init<Configuration, Bar: View>( configuration: Configuration, contentPlacement: @escaping ( Configuration ) -> RouterNavigationBarContentPlacement, @ViewBuilder content: @escaping ( Configuration, RouterNavigationBarContext ) -> Bar )
    {
        configurationType = ObjectIdentifier( Configuration.self )
        defaultConfiguration = configuration
        makeView = { configuration, context in
            guard let configuration = configuration as? Configuration else
            {
                assertionFailure( "Router navigation bar configuration type mismatch." )
                return AnyView( EmptyView() )
            }

            return AnyView( content( configuration, context ) )
        }
        self.contentPlacement = { configuration in
            guard let configuration = configuration as? Configuration else
            {
                assertionFailure( "Router navigation bar configuration type mismatch." )
                return .inset( spacing: 0 )
            }

            return contentPlacement( configuration )
        }
    }
}

@MainActor
struct AnyRouterNavigationBarUpdate
{
    let configurationType: ObjectIdentifier
    let apply: ( Any ) -> Any

    init<Configuration>( update: @escaping ( inout Configuration ) -> Void )
    {
        configurationType = ObjectIdentifier( Configuration.self )
        apply = { configuration in
            guard var configuration = configuration as? Configuration else
            {
                assertionFailure( "Router navigation bar configuration type mismatch." )
                return configuration
            }

            update( &configuration )
            return configuration
        }
    }
}

@MainActor
enum RouterNavigationBarResolution
{
    case custom( AnyView, contentPlacement: RouterNavigationBarContentPlacement )
    case native
    case hidden
}

@MainActor
final class RouterNavigationBarStore: ObservableObject
{
    private struct Update
    {
        let order: Int
        let value: AnyRouterNavigationBarUpdate
    }

    private struct Replacement
    {
        let order: Int
        let makeView: () -> AnyView
    }

    private struct EntryOverrides
    {
        var updates = [UUID: Update]()
        var replacements = [UUID: Replacement]()
        var nativeTokens = Set<UUID>()
        var hiddenTokens = Set<UUID>()
    }

    @Published
    private( set ) var revision = 0

    private var entries = [String: EntryOverrides]()
    private var nextOrder = 0

    func SetUpdate( entryID: String, token: UUID, update: AnyRouterNavigationBarUpdate )
    {
        var overrides = entries[entryID] ?? EntryOverrides()

        if let previous = overrides.updates[token]
        {
            overrides.updates[token] = Update( order: previous.order, value: update )
        }
        else
        {
            overrides.updates[token] = Update( order: NextOrder(), value: update )
        }

        entries[entryID] = overrides
        Changed()
    }

    func RemoveUpdate( entryID: String, token: UUID )
    {
        guard var overrides = entries[entryID] else { return }

        overrides.updates[token] = nil
        Save( overrides, for: entryID )
    }

    func SetReplacement( entryID: String, token: UUID, makeView: @escaping () -> AnyView )
    {
        var overrides = entries[entryID] ?? EntryOverrides()

        if let previous = overrides.replacements[token]
        {
            overrides.replacements[token] = Replacement( order: previous.order, makeView: makeView )
        }
        else
        {
            overrides.replacements[token] = Replacement( order: NextOrder(), makeView: makeView )
        }

        entries[entryID] = overrides
        Changed()
    }

    func RemoveReplacement( entryID: String, token: UUID )
    {
        guard var overrides = entries[entryID] else { return }

        overrides.replacements[token] = nil
        Save( overrides, for: entryID )
    }

    func SetNative( entryID: String, token: UUID )
    {
        var overrides = entries[entryID] ?? EntryOverrides()
        overrides.nativeTokens.insert( token )
        entries[entryID] = overrides
        Changed()
    }

    func RemoveNative( entryID: String, token: UUID )
    {
        guard var overrides = entries[entryID] else { return }

        overrides.nativeTokens.remove( token )
        Save( overrides, for: entryID )
    }

    func SetHidden( entryID: String, token: UUID )
    {
        var overrides = entries[entryID] ?? EntryOverrides()
        overrides.hiddenTokens.insert( token )
        entries[entryID] = overrides
        Changed()
    }

    func RemoveHidden( entryID: String, token: UUID )
    {
        guard var overrides = entries[entryID] else { return }

        overrides.hiddenTokens.remove( token )
        Save( overrides, for: entryID )
    }

    func Resolve( provider: AnyRouterNavigationBarProvider?, entry: RouteEntry, context: RouterNavigationBarContext ) -> RouterNavigationBarResolution
    {
        let overrides = entries[entry.id]

        if let replacement = overrides?.replacements.values.max( by: { $0.order < $1.order } )
        {
            guard let provider else
            {
                return .custom( replacement.makeView(), contentPlacement: .inset( spacing: 0 ) )
            }

            let configuration = Configuration( provider: provider, overrides: overrides )
            return .custom( replacement.makeView(), contentPlacement: provider.contentPlacement( configuration ) )
        }

        if overrides?.hiddenTokens.isEmpty == false
        {
            return .hidden
        }

        if overrides?.nativeTokens.isEmpty == false || provider == nil
        {
            return .native
        }

        guard let provider else { return .native }
        let configuration = Configuration( provider: provider, overrides: overrides )
        return .custom(
            provider.makeView( configuration, context ),
            contentPlacement: provider.contentPlacement( configuration ) )
    }

    private func Configuration( provider: AnyRouterNavigationBarProvider, overrides: EntryOverrides? ) -> Any
    {
        var configuration = provider.defaultConfiguration

        for update in overrides?.updates.values.sorted( by: { $0.order < $1.order } ) ?? []
        {
            guard update.value.configurationType == provider.configurationType else
            {
                assertionFailure( "Router navigation bar update configuration type does not match the host configuration type." )
                continue
            }

            configuration = update.value.apply( configuration )
        }

        return configuration
    }

    private func NextOrder() -> Int
    {
        defer { nextOrder += 1 }
        return nextOrder
    }

    private func Save( _ overrides: EntryOverrides, for entryID: String )
    {
        if overrides.updates.isEmpty && overrides.replacements.isEmpty && overrides.nativeTokens.isEmpty && overrides.hiddenTokens.isEmpty
        {
            entries[entryID] = nil
        }
        else
        {
            entries[entryID] = overrides
        }

        Changed()
    }

    private func Changed()
    {
        revision &+= 1
    }
}

@MainActor
struct RouterNavigationBarEntryHost<Content: View>: View
{
    @ObservedObject
    private var store: RouterNavigationBarStore

    private let provider: AnyRouterNavigationBarProvider?
    private let entry: RouteEntry
    private let canGoBack: Bool
    private let back: () -> Void
    private let content: Content

    init( store: RouterNavigationBarStore, provider: AnyRouterNavigationBarProvider?, entry: RouteEntry, canGoBack: Bool, back: @escaping () -> Void, @ViewBuilder content: () -> Content )
    {
        self.store = store
        self.provider = provider
        self.entry = entry
        self.canGoBack = canGoBack
        self.back = back
        self.content = content()
    }

    @ViewBuilder
    var body: some View
    {
        let _ = store.revision

        switch Resolution()
        {
        case .custom( let navigationBar, let contentPlacement ):
            CustomContent(
                navigationBar: navigationBar,
                contentPlacement: contentPlacement )

        case .native:
            #if os(iOS)
            ExpandedContent()
                .toolbar( .visible, for: .navigationBar )
            #else
            ExpandedContent()
            #endif

        case .hidden:
            #if os(iOS)
            ExpandedContent()
                .toolbar( .hidden, for: .navigationBar )
            #else
            ExpandedContent()
            #endif
        }
    }

    @ViewBuilder
    private func CustomContent( navigationBar: AnyView, contentPlacement: RouterNavigationBarContentPlacement ) -> some View
    {
        switch contentPlacement
        {
        case .inset( let spacing ):
            #if os(iOS)
            ExpandedContent()
                .toolbar( .hidden, for: .navigationBar )
                .safeAreaInset(
                    edge: .top,
                    spacing: spacing
                )
                {
                    navigationBar
                }
            #else
            ExpandedContent()
                .safeAreaInset(
                    edge: .top,
                    spacing: spacing
                )
                {
                    navigationBar
                }
            #endif

        case .overlay:
            #if os(iOS)
            ExpandedContent()
                .toolbar( .hidden, for: .navigationBar )
                .overlay( alignment: .top )
                {
                    navigationBar
                }
            #else
            ExpandedContent()
                .overlay( alignment: .top )
                {
                    navigationBar
                }
            #endif
        }
    }
    
    private func ExpandedContent() -> some View
    {
        content
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
    }

    private func Resolution() -> RouterNavigationBarResolution
    {
        store.Resolve(
            provider: provider,
            entry: entry,
            context: RouterNavigationBarContext(
                entry: entry,
                canGoBack: canGoBack,
                back: back ) )
    }
}

@MainActor
private struct RouterNavigationBarUpdateModifier<Configuration>: ViewModifier
{
    @Environment( \.routeEntry )
    private var routeEntry

    @Environment( \.routerNavigationBarStore )
    private var store

    @State
    private var token = UUID()

    let update: ( inout Configuration ) -> Void

    func body( content: Content ) -> some View
    {
        content
            .onAppear { Register() }
            .onDisappear { Unregister() }
    }

    private func Register()
    {
        guard let routeEntry, let store else { return }

        store.SetUpdate( entryID: routeEntry.id, token: token, update: AnyRouterNavigationBarUpdate( update: update ) )
    }

    private func Unregister()
    {
        guard let routeEntry, let store else { return }

        store.RemoveUpdate( entryID: routeEntry.id, token: token )
    }
}

@MainActor
private struct RouterNavigationBarValueUpdateModifier<Value: Equatable, Configuration>: ViewModifier
{
    @Environment( \.routeEntry )
    private var routeEntry

    @Environment( \.routerNavigationBarStore )
    private var store

    @State
    private var token = UUID()

    let value: Value
    let update: ( inout Configuration, Value ) -> Void

    func body( content: Content ) -> some View
    {
        content
            .onAppear { Register() }
            .onDisappear { Unregister() }
            .onChange( of: value ) { _ in Register() }
    }

    private func Register()
    {
        guard let routeEntry, let store else { return }

        store.SetUpdate( entryID: routeEntry.id, token: token, update: AnyRouterNavigationBarUpdate {
            update( &$0, value )
        } )
    }

    private func Unregister()
    {
        guard let routeEntry, let store else { return }

        store.RemoveUpdate( entryID: routeEntry.id, token: token )
    }
}

@MainActor
private struct RouterNavigationBarReplacementModifier<Bar: View>: ViewModifier
{
    @Environment( \.routeEntry )
    private var routeEntry

    @Environment( \.routerNavigationBarStore )
    private var store

    @State
    private var token = UUID()

    let replacement: () -> Bar

    func body( content: Content ) -> some View
    {
        content
            .onAppear { Register() }
            .onDisappear { Unregister() }
    }

    private func Register()
    {
        guard let routeEntry, let store else { return }

        store.SetReplacement( entryID: routeEntry.id, token: token ) {
            AnyView( replacement() )
        }
    }

    private func Unregister()
    {
        guard let routeEntry, let store else { return }

        store.RemoveReplacement( entryID: routeEntry.id, token: token )
    }
}

@MainActor
private struct RouterNavigationBarNativeModifier: ViewModifier
{
    @Environment( \.routeEntry )
    private var routeEntry

    @Environment( \.routerNavigationBarStore )
    private var store

    @State
    private var token = UUID()

    func body( content: Content ) -> some View
    {
        content
            .onAppear { Register() }
            .onDisappear { Unregister() }
    }

    private func Register()
    {
        guard let routeEntry, let store else { return }

        store.SetNative( entryID: routeEntry.id, token: token )
    }

    private func Unregister()
    {
        guard let routeEntry, let store else { return }

        store.RemoveNative( entryID: routeEntry.id, token: token )
    }
}

@MainActor
private struct RouterNavigationBarHiddenModifier: ViewModifier
{
    @Environment( \.routeEntry )
    private var routeEntry

    @Environment( \.routerNavigationBarStore )
    private var store

    @State
    private var token = UUID()

    func body( content: Content ) -> some View
    {
        content
            .onAppear { Register() }
            .onDisappear { Unregister() }
    }

    private func Register()
    {
        guard let routeEntry, let store else { return }

        store.SetHidden( entryID: routeEntry.id, token: token )
    }

    private func Unregister()
    {
        guard let routeEntry, let store else { return }

        store.RemoveHidden( entryID: routeEntry.id, token: token )
    }
}

@MainActor
public extension View
{
    func routerNavigationBar<Configuration, Bar: View>( default configuration: Configuration, @ViewBuilder content: @escaping ( Configuration, RouterNavigationBarContext ) -> Bar ) -> some View
    {
        environment( \.routerNavigationBarProvider, AnyRouterNavigationBarProvider( configuration: configuration, content: content ) )
    }

    func routerNavigationBar<Configuration, Bar: View>( default configuration: Configuration, contentSpacing: KeyPath<Configuration, CGFloat>, @ViewBuilder content: @escaping ( Configuration, RouterNavigationBarContext ) -> Bar ) -> some View
    {
        environment( \.routerNavigationBarProvider, AnyRouterNavigationBarProvider(
            configuration: configuration,
            contentSpacing: { $0[keyPath: contentSpacing] },
            content: content ) )
    }

    func routerNavigationBar<Configuration, Bar: View>( default configuration: Configuration, contentPlacement: KeyPath<Configuration, RouterNavigationBarContentPlacement>, @ViewBuilder content: @escaping ( Configuration, RouterNavigationBarContext ) -> Bar ) -> some View
    {
        environment( \.routerNavigationBarProvider, AnyRouterNavigationBarProvider(
            configuration: configuration,
            contentPlacement: { $0[keyPath: contentPlacement] },
            content: content ) )
    }

    func routerNavigationBar<Configuration>( update: @escaping ( inout Configuration ) -> Void ) -> some View
    {
        modifier( RouterNavigationBarUpdateModifier( update: update ) )
    }

    func routerNavigationBar<Value: Equatable, Configuration>( value: Value, update: @escaping ( inout Configuration, Value ) -> Void ) -> some View
    {
        modifier( RouterNavigationBarValueUpdateModifier( value: value, update: update ) )
    }

    func routerNavigationBar<Bar: View>( @ViewBuilder replacement: @escaping () -> Bar ) -> some View
    {
        modifier( RouterNavigationBarReplacementModifier( replacement: replacement ) )
    }

    func routerNavigationBarNative() -> some View
    {
        modifier( RouterNavigationBarNativeModifier() )
    }

    func routerNavigationBarHidden() -> some View
    {
        modifier( RouterNavigationBarHiddenModifier() )
    }
}
