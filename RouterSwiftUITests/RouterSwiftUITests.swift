import Combine
import SwiftUI
import Testing
@testable import RouterSwiftUI

struct TestHomePath: RoutePath, EmptyParamsPath
{
    init(   )
    {
    }
}

struct TestProfilePath: RoutePath
{
    let id: Int

    init(    id: Int )
    {
        self.id = id
    }
}

struct TestSettingsPath: RoutePath
{
    let section: String
}

struct TestTabsPath: RoutePath, EmptyParamsPath
{
    init(   )
    {
    }
}

struct TestTabAPath: RoutePath, EmptyParamsPath
{
    init(   )
    {
    }
}

struct TestTabBPath: RoutePath, EmptyParamsPath
{
    init(   )
    {
    }
}

struct TestSecurePath: RoutePath, EmptyParamsPath
{
    init(   )
    {
    }
}

struct TestLoginPath: RoutePath, EmptyParamsPath
{
    init(   )
    {
    }
}

struct TestDialogPath: RoutePath, EmptyParamsPath
{
    init()
    {
    }
}

struct TestBottomSheetPath: RoutePath, EmptyParamsPath
{
    init()
    {
    }
}

struct TestGeneratedPlainPath: RoutePath, EmptyParamsPath
{
    init(   )
    {
    }
}

struct TestGeneratedVMPath: RoutePath, EmptyParamsPath
{
    init(   )
    {
    }
}

struct TestPartialVMFactoryPath: RoutePath, EmptyParamsPath
{
    init(   )
    {
    }
}

struct TestPartialViewFactoryPath: RoutePath, EmptyParamsPath
{
    init(   )
    {
    }
}

struct TestGatePath: RoutePath
{
    let next: RouteParams
}

struct TestGateTargetPath: RoutePath, EmptyParamsPath
{
    init()
    {
    }
}

struct TestTextView: RouterView
{
    let text: String

    var body: some View
    {
        Text(    text )
    }
}

struct TestDialogView: RouterDialogView
{
    var body: some View
    {
        Text(    "Dialog" )
    }
}

struct TestSheetView: RouterBottomSheetView
{
    var body: some View
    {
        Text(    "Sheet" )
    }
}

struct TestGeneratedPlainView: RouterView
{
    init(   )
    {
    }

    var body: some View
    {
        Text(    "Generated plain" )
    }
}

struct TestGeneratedVMView: RouterView
{
    @ObservedObject
    var viewModel: TestGeneratedViewModel

    init(    viewModel: TestGeneratedViewModel )
    {
        self.viewModel = viewModel
    }

    var body: some View
    {
        Text(    viewModel.title )
    }
}

final class TestProfileViewModel: RouterViewModel
{
    var id = 0

    override func OnRouterBound()
    {
        id += 1
    }
}

final class TestGeneratedViewModel: RouterViewModel
{
    var title = "Generated VM"
}

final class TestAuthMiddleware: MiddlewareController
{
    static var allowSecure = false

    init(   )
    {
    }

    func OnRoute(    router: any Router, previous: AnyRoutePath?, next: RouteParams ) -> Bool
    {
        guard next.path.Typed(    TestSecurePath.self ) != nil, Self.allowSecure == false else { return false }

        router.Route(    TestLoginPath(   ) )
        return true
    }
}

final class TestGateMiddleware: MiddlewareController
{
    static var allow = false

    init()
    {
    }

    func OnRoute( router: any Router, previous: AnyRoutePath?, next: RouteParams ) -> Bool
    {
        guard next.path.Typed( TestGateTargetPath.self ) != nil, Self.allow == false else { return false }

        router.Route( TestGatePath( next: next ) )
        return true
    }
}

@GlobalMiddleware( order: 0 )
final class TestGlobalMiddleware: MiddlewareController
{
    static var routeCount = 0

    init(   )
    {
    }

    func OnRoute(    router: any Router, previous: AnyRoutePath?, next: RouteParams ) -> Bool
    {
        Self.routeCount += 1
        return false
    }
}

@Route( uri: "/", singleTop: .equal )
final class TestHomeController: RouteController<TestHomePath, TestTextView>
{
    override func OnCreateView(    path: TestHomePath ) -> TestTextView
    {
        TestTextView(    text: "Home" )
    }
}

@Route( uri: "/profile/:id", singleTop: .class )
final class TestProfileController: RouteControllerVM<TestProfilePath, TestProfileViewModel, TestTextView>
{
    override func Convert(    path: [String: String], query: [String: String] ) -> TestProfilePath?
    {
        guard let id = Int(    path["id"] ?? "" ) else { return nil }

        return TestProfilePath(    id: id )
    }

    override func OnCreateViewModel(    path: TestProfilePath ) -> TestProfileViewModel
    {
        let viewModel = TestProfileViewModel(   )
        viewModel.id = path.id
        return viewModel
    }

    override func OnCreateView(    path: TestProfilePath, viewModel: TestProfileViewModel ) -> TestTextView
    {
        TestTextView(    text: "Profile \(   viewModel.id)" )
    }
}

@Route( uri: "/settings", singleTop: .equal )
final class TestSettingsController: RouteController<TestSettingsPath, TestTextView>
{
    override func OnCreateView(    path: TestSettingsPath ) -> TestTextView
    {
        TestTextView(    text: path.section )
    }
}

@Route( uri: "/tabs" )
final class TestTabsController: RouteController<TestTabsPath, TestTextView>
{
    override func OnCreateView(    path: TestTabsPath ) -> TestTextView
    {
        TestTextView(    text: "Tabs" )
    }
}

@Route( uri: "/tab-a", singleTop: .equal )
final class TestTabAController: RouteController<TestTabAPath, TestTextView>
{
    override func OnCreateView(    path: TestTabAPath ) -> TestTextView
    {
        TestTextView(    text: "A" )
    }
}

@Route( uri: "/tab-b", singleTop: .equal )
final class TestTabBController: RouteController<TestTabBPath, TestTextView>
{
    override func OnCreateView(    path: TestTabBPath ) -> TestTextView
    {
        TestTextView(    text: "B" )
    }
}

@Route( uri: "/secure" )
@UseMiddlewares( TestAuthMiddleware.self )
final class TestSecureController: RouteController<TestSecurePath, TestTextView>
{
    override func OnCreateView(    path: TestSecurePath ) -> TestTextView
    {
        TestTextView(    text: "Secure" )
    }
}

@Route( uri: "/login" )
final class TestLoginController: RouteController<TestLoginPath, TestTextView>
{
    override func OnCreateView(    path: TestLoginPath ) -> TestTextView
    {
        TestTextView(    text: "Login" )
    }
}

@Route( uri: "/dialog" )
final class TestDialogController: RouteController<TestDialogPath, TestDialogView>
{
}

@Route( uri: "/bottom-sheet" )
final class TestBottomSheetController: RouteController<TestBottomSheetPath, TestSheetView>
{
}

@Route( uri: "/generated-plain" )
final class TestGeneratedPlainController: RouteController<TestGeneratedPlainPath, TestGeneratedPlainView>
{
}

@Route( uri: "/generated-vm" )
final class TestGeneratedVMController: RouteControllerVM<TestGeneratedVMPath, TestGeneratedViewModel, TestGeneratedVMView>
{
}

@Route( uri: "/partial-vm-factory" )
final class TestPartialVMFactoryController: RouteControllerVM<TestPartialVMFactoryPath, TestGeneratedViewModel, TestGeneratedVMView>
{
    override func OnCreateViewModel(    path: TestPartialVMFactoryPath ) -> TestGeneratedViewModel
    {
        let viewModel = TestGeneratedViewModel(   )
        viewModel.title = "Manual VM"
        return viewModel
    }
}

@Route( uri: "/partial-view-factory" )
final class TestPartialViewFactoryController: RouteControllerVM<TestPartialViewFactoryPath, TestGeneratedViewModel, TestGeneratedVMView>
{
    override func OnCreateView(    path: TestPartialViewFactoryPath, viewModel: TestGeneratedViewModel ) -> TestGeneratedVMView
    {
        viewModel.title = "Manual View"
        return TestGeneratedVMView(    viewModel: viewModel )
    }
}

@Route( uri: "/gate" )
final class TestGateController: RouteController<TestGatePath, TestTextView>
{
    override func OnCreateView( path: TestGatePath ) -> TestTextView
    {
        TestTextView( text: "Gate" )
    }
}

@Route( uri: "/gate-target" )
@UseMiddlewares( TestGateMiddleware.self )
final class TestGateTargetController: RouteController<TestGateTargetPath, TestTextView>
{
    override func OnCreateView( path: TestGateTargetPath ) -> TestTextView
    {
        TestTextView( text: "Gate Target" )
    }
}

@MainActor
struct RouterSwiftUITests
{
    @Test
    func RoutingAndDeeplink(   ) throws
    {
        let router = MakeRouter(   )

        router.Route(    TestHomePath(   ) )
        router.Route(    TestProfilePath(    id: 1 ) )

        #expect(    router.viewStack.count == 2 )
        #expect(    router.viewStack.last?.path.Typed(    TestProfilePath.self )?.id == 1 )

        router.Route(    url: "/profile/42?mode=full" )
        #expect(    router.viewStack.count == 2 )
        #expect(    router.viewStack.last?.path.Typed(    TestProfilePath.self )?.id == 1 )
    }

    @Test
    func SingleTopClassAndEqual(   ) throws
    {
        let router = MakeRouter(   )

        router.Route(    TestHomePath(   ) )
        router.Route(    TestProfilePath(    id: 1 ) )
        router.Route(    TestSettingsPath(    section: "one" ) )
        router.Route(    TestProfilePath(    id: 2 ) )

        #expect(    router.viewStack.count == 2 )
        #expect(    router.viewStack.last?.path.Typed(    TestProfilePath.self )?.id == 1 )

        router.Route(    TestSettingsPath(    section: "one" ) )
        router.Route(    TestSettingsPath(    section: "two" ) )

        #expect(    router.viewStack.count == 4 )
        #expect(    router.viewStack.last?.path.Typed(    TestSettingsPath.self )?.section == "two" )
    }

    @Test
    func TabSwitchingAndRouteToExistingTab(   ) throws
    {
        let router = MakeRouter(   )
        router.Route(    TestTabsPath(   ) )
        let tabsEntry = try #require(    router.viewStack.last )
        let tabs = router.CreateTabs(   
            viewKey: tabsEntry.id,
            descriptors: [
                RouterTabDescriptor(    id: "a", index: 0, title: "A", rootPath: TestTabAPath(   ) ),
                RouterTabDescriptor(    id: "b", index: 1, title: "B", rootPath: TestTabBPath(   ) )
            ] )

        tabs.Router(    for: 0 ).Route(    TestTabAPath(   ) )
        tabs.Router(    for: 1 ).Route(    TestTabBPath(   ) )

        #expect(    tabs.tabIndex == 0 )
        #expect(    tabs.Route(    1 ) )
        #expect(    tabs.tabIndex == 1 )

        _ = tabs.Route(    0 )
        router.Route(    TestTabBPath(   ) )
        #expect(    tabs.tabIndex == 1 )
        #expect(    router.viewStack.count == 1 )
    }

    @Test
    func TabRootsAreRegisteredBeforeTabSelection(   ) throws
    {
        let router = MakeRouter(   )
        router.Route(    TestTabsPath(   ) )
        let tabsEntry = try #require(    router.viewStack.last )
        let tabs = router.CreateTabs(
            viewKey: tabsEntry.id,
            descriptors: [
                RouterTabDescriptor(    id: "a", index: 0, title: "A", rootPath: TestTabAPath(   ) ),
                RouterTabDescriptor(    id: "b", index: 1, title: "B", rootPath: TestTabBPath(   ) )
            ] )

        tabs.Route(    0, path: TestTabAPath(   ) )
        tabs.Route(    1, path: TestTabBPath(   ) )

        #expect(    tabs.Router(    for: 0 ).viewStack.count == 1 )
        #expect(    tabs.Router(    for: 1 ).viewStack.count == 1 )

        _ = tabs.Route(    0 )
        tabs.Router(    for: 0 ).Route(    TestTabBPath(   ) )

        #expect(    tabs.tabIndex == 1 )
        #expect(    tabs.Router(    for: 0 ).viewStack.count == 1 )
        #expect(    tabs.Router(    for: 0 ).viewStack.last?.path.Typed(    TestTabAPath.self ) != nil )
        #expect(    tabs.Router(    for: 1 ).viewStack.last?.path.Typed(    TestTabBPath.self ) != nil )
    }

    @Test
    func MiddlewareRedirectAndGlobalMiddleware(   ) throws
    {
        TestAuthMiddleware.allowSecure = false
        TestGlobalMiddleware.routeCount = 0

        let router = MakeRouter(   )
        router.Route(    TestHomePath(   ) )
        router.Route(    TestSecurePath(   ) )

        #expect(    router.viewStack.last?.path.Typed(    TestLoginPath.self ) != nil )
        #expect(    router.viewStack.contains { $0.path.Typed(    TestSecurePath.self ) != nil } == false )
        #expect(    TestGlobalMiddleware.routeCount > 0 )
    }

    @Test
    func ViewModelLifecycleIsEntryBound(   ) throws
    {
        let router = MakeRouter(   )
        router.Route(    TestProfilePath(    id: 7 ) )

        let entry = try #require(    router.viewStack.last )
        let firstViewModel = try #require(    entry.viewModel as? TestProfileViewModel )
        _ = try entry.controller.MakeView(    entry: entry )
        _ = try entry.controller.MakeView(    entry: entry )

        #expect(    entry.viewModel === firstViewModel )
        #expect(    firstViewModel.id == 8 )
    }

    @Test
    func RouteMacroGeneratesDefaultFactories(   ) throws
    {
        let router = MakeRouter(   )

        router.Route(    TestGeneratedPlainPath(   ) )
        var entry = try #require(    router.viewStack.last )
        _ = try entry.controller.MakeView(    entry: entry )
        #expect(    entry.path.Typed(    TestGeneratedPlainPath.self ) != nil )

        router.Route(    TestGeneratedVMPath(   ) )
        entry = try #require(    router.viewStack.last )
        _ = try entry.controller.MakeView(    entry: entry )
        #expect(    entry.viewModel is TestGeneratedViewModel )

        router.Route(    TestPartialVMFactoryPath(   ) )
        entry = try #require(    router.viewStack.last )
        _ = try entry.controller.MakeView(    entry: entry )
        #expect(    (    entry.viewModel as? TestGeneratedViewModel )?.title == "Manual VM" )

        router.Route(    TestPartialViewFactoryPath(   ) )
        entry = try #require(    router.viewStack.last )
        _ = try entry.controller.MakeView(    entry: entry )
        #expect(    (    entry.viewModel as? TestGeneratedViewModel )?.title == "Manual View" )
    }

    @Test
    func DuplicateRegistryDetection(   ) throws
    {
        #expect(    throws: RouterError.self ) {
            try RouteRegistry(    routes: [
                RouteRegistration(    TestHomeController(   ), uri: "/dup" ),
                RouteRegistration(    TestHomeController(   ), uri: "/dup" )
            ] )
        }
    }

    @Test
    func NavigatorDerivesPresentationsFromItems() throws
    {
        let router = MakeRouter()
        let navigator = SwiftUINavigator()

        router.BindExecutor( SwiftUICommandExecutor( navigator: navigator ) )
        router.Route( TestHomePath() )
        router.Route( TestDialogPath() )
        router.Route( TestSettingsPath( section: "next" ) )

        #expect( navigator.items.count == 3 )
        #expect( navigator.sheet == nil )
        #expect( navigator.stack.last?.path.Typed( TestSettingsPath.self )?.section == "next" )

        router.Back()

        #expect( navigator.items.count == 2 )
        #expect( navigator.sheet?.path.Typed( TestDialogPath.self ) != nil )

        router.Route( TestBottomSheetPath() )
        #expect( navigator.sheet == nil )
        #expect( navigator.bottomSheet?.path.Typed( TestBottomSheetPath.self ) != nil )
    }

    @Test
    func RouteResultCallbackReceivesValuesUntilClose() throws
    {
        let router = MakeRouter()
        let navigator = SwiftUINavigator()
        var values = [String]()

        router.BindExecutor( SwiftUICommandExecutor( navigator: navigator ) )
        router.Route( TestHomePath() )
        router.RouteWithResult( TestSettingsPath( section: "callback" ) ) { values.append( $0 ) }

        var entry = try #require( router.viewStack.last )
        entry.resultProvider.Send( "one" )
        entry.resultProvider.Send( "two" )
        router.Close()
        entry = router.viewStack.first!

        #expect( values == ["one", "two"] )
    }

    @Test
    func RouteForResultReturnsFirstValue() async throws
    {
        let router = MakeRouter()
        router.Route( TestHomePath() )

        let task = Task { @MainActor in
            await router.RouteForResult( TestSettingsPath( section: "await" ) ) as String?
        }

        await Task.yield()

        let entry = try #require( router.viewStack.last )
        entry.resultProvider.Send( "first" )
        entry.resultProvider.Send( "second" )

        let result = await task.value
        #expect( result == "first" )
    }

    @Test
    func RouteForResultReturnsNilWhenClosed() async throws
    {
        let router = MakeRouter()
        let navigator = SwiftUINavigator()

        router.BindExecutor( SwiftUICommandExecutor( navigator: navigator ) )
        router.Route( TestHomePath() )

        let task = Task { @MainActor in
            await router.RouteForResult( TestSettingsPath( section: "await-close" ) ) as String?
        }

        await Task.yield()

        router.Close()

        let result = await task.value
        #expect( result == nil )
    }

    @Test
    func RouteForResultsFinishesWhenClosed() async throws
    {
        let router = MakeRouter()
        let navigator = SwiftUINavigator()

        router.BindExecutor( SwiftUICommandExecutor( navigator: navigator ) )
        router.Route( TestHomePath() )

        let stream = router.RouteForResults( TestSettingsPath( section: "stream" ), as: String.self )
        var entry = try #require( router.viewStack.last )

        entry.resultProvider.Send( "one" )
        entry.resultProvider.Send( "two" )
        router.Close()
        entry = router.viewStack.first!

        var iterator = stream.makeAsyncIterator()
        let first = await iterator.next()
        let second = await iterator.next()
        let end = await iterator.next()

        #expect( first == "one" )
        #expect( second == "two" )
        #expect( end == nil )
    }

    @Test
    func RouteResultPublisherFinishesWhenClosed() throws
    {
        let router = MakeRouter()
        let navigator = SwiftUINavigator()
        var values = [String]()
        var finished = false
        var cancellables = Set<AnyCancellable>()

        router.BindExecutor( SwiftUICommandExecutor( navigator: navigator ) )
        router.Route( TestHomePath() )
        router.RouteResultPublisher( TestSettingsPath( section: "publisher" ), as: String.self )
            .sink(
                receiveCompletion: {
                    if case .finished = $0
                    {
                        finished = true
                    }
                },
                receiveValue: { values.append( $0 ) } )
            .store( in: &cancellables )

        var entry = try #require( router.viewStack.last )
        entry.resultProvider.Send( "one" )
        entry.resultProvider.Send( "two" )
        router.Close()
        entry = router.viewStack.first!

        #expect( values == ["one", "two"] )
        #expect( finished )
        #expect( cancellables.isEmpty == false )
    }

    @Test
    func RouteForResultReturnsNilWhenNavigatorRemovesEntry() async throws
    {
        let router = MakeRouter()
        let navigator = SwiftUINavigator()

        router.BindExecutor( SwiftUICommandExecutor( navigator: navigator ) )
        router.Route( TestHomePath() )

        let task = Task { @MainActor in
            await router.RouteForResult( TestSettingsPath( section: "sync-close" ) ) as String?
        }

        await Task.yield()

        navigator.stack = []
        router.SyncVisibleEntries( navigator.visibleEntryIDs )

        let result = await task.value
        #expect( result == nil )
    }

    @Test
    func MiddlewarePreservesRouteResultForRetry() throws
    {
        TestGateMiddleware.allow = false

        let router = MakeRouter()
        var values = [String]()

        router.Route( TestHomePath() )
        router.RouteWithResult( TestGateTargetPath() ) { values.append( $0 ) }

        let gateEntry = try #require( router.viewStack.last )
        let gatePath = try #require( gateEntry.path.Typed( TestGatePath.self ) )

        #expect( gatePath.next.hasResult )

        TestGateMiddleware.allow = true
        router.Close()
        router.Route( gatePath.next )

        let targetEntry = try #require( router.viewStack.last )
        #expect( targetEntry.path.Typed( TestGateTargetPath.self ) != nil )

        targetEntry.resultProvider.Send( "done" )

        #expect( values == ["done"] )
    }

    private func MakeRouter(   ) -> RouterSimple
    {
        RouterSimple(    registry: GeneratedRouteRegistry.Make(   ) )
    }
}
