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

private struct TestNavigationBarConfiguration
{
    var contentSpacing: CGFloat
    var contentPlacement = RouterNavigationBarContentPlacement.inset( spacing: 8 )
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
    static var secureRouteCount = 0

    init(   )
    {
    }

    func OnRoute(    router: any Router, previous: AnyRoutePath?, next: RouteParams ) -> Bool
    {
        guard next.path.Typed(    TestSecurePath.self ) != nil else { return false }

        Self.secureRouteCount += 1
        guard Self.allowSecure == false else { return false }

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
    static var beforeRouteCount = 0

    init(   )
    {
    }

    func OnBeforeRoute( router: any Router, current: AnyRoutePath, next: RouteParams ) -> Bool
    {
        Self.beforeRouteCount += 1
        return false
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
    static var beforeRouteCount = 0

    override func OnCreateView(    path: TestTabsPath ) -> TestTextView
    {
        TestTextView(    text: "Tabs" )
    }

    override func OnBeforeRoute( router: any Router, current: TestTabsPath, next: RouteParams ) -> Bool
    {
        Self.beforeRouteCount += 1
        return false
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
    func ProtectedTabMiddlewareRunsInParentOnSelectionAndPathRouting() throws
    {
        TestAuthMiddleware.allowSecure = false
        TestAuthMiddleware.secureRouteCount = 0
        TestGlobalMiddleware.beforeRouteCount = 0
        TestGlobalMiddleware.routeCount = 0
        TestTabsController.beforeRouteCount = 0

        let router = MakeRouter()
        router.Route( TestTabsPath() )
        let tabsEntry = try #require( router.viewStack.last )
        let descriptors = [
            RouterTabDescriptor( id: "home", index: 0, title: "Home", rootPath: TestTabAPath() ),
            RouterTabDescriptor( id: "profile", index: 1, title: "Profile", rootPath: TestSecurePath() )
        ]
        let tabs = router.CreateTabs( viewKey: tabsEntry.id, descriptors: descriptors )

        for descriptor in descriptors
        {
            tabs.Route( descriptor.index, path: descriptor.rootPath, recreate: false )
        }

        let homeRouter = tabs.Router( for: 0 )
        let profileRouter = tabs.Router( for: 1 )
        let routeCountAfterEagerInitialization = TestGlobalMiddleware.routeCount

        #expect( homeRouter.viewStack.count == 1 )
        #expect( homeRouter.viewStack.last?.path.Typed( TestTabAPath.self ) != nil )
        #expect( profileRouter.viewStack.count == 1 )
        #expect( profileRouter.viewStack.last?.path.Typed( TestSecurePath.self ) != nil )
        #expect( TestAuthMiddleware.secureRouteCount == 0 )
        #expect( router.viewStack.count == 1 )
        #expect( router.viewStack.contains { $0.path.Typed( TestLoginPath.self ) != nil } == false )

        #expect( tabs.Route( 1 ) == false )
        #expect( tabs.tabIndex == 0 )
        #expect( TestAuthMiddleware.secureRouteCount == 1 )
        #expect( TestGlobalMiddleware.routeCount > routeCountAfterEagerInitialization )
        #expect( TestTabsController.beforeRouteCount > 0 )
        #expect( TestGlobalMiddleware.beforeRouteCount > 0 )
        #expect( router.viewStack.count == 2 )
        #expect( router.viewStack.last?.path.Typed( TestLoginPath.self ) != nil )
        #expect( router.viewStack.contains { $0.path.Typed( TestSecurePath.self ) != nil } == false )
        #expect( profileRouter.viewStack.count == 1 )
        #expect( profileRouter.viewStack.last?.path.Typed( TestSecurePath.self ) != nil )

        TestAuthMiddleware.allowSecure = true
        let resumed = router.Close()?.Route( RouteParams( path: TestSecurePath(), tabIndex: 1 ) )

        #expect( (resumed as? RouterTabSimple) === profileRouter )
        #expect( tabs.tabIndex == 1 )
        #expect( TestAuthMiddleware.secureRouteCount == 2 )
        #expect( router.viewStack.count == 1 )
        #expect( profileRouter.viewStack.count == 1 )
        #expect( profileRouter.viewStack.last?.path.Typed( TestSecurePath.self ) != nil )

        #expect( tabs.Route( 0 ) )
        TestAuthMiddleware.allowSecure = false
        let routed = router.Route( TestSecurePath() )

        #expect( routed == nil )
        #expect( tabs.tabIndex == 0 )
        #expect( TestAuthMiddleware.secureRouteCount == 3 )
        #expect( router.viewStack.count == 2 )
        #expect( router.viewStack.last?.path.Typed( TestLoginPath.self ) != nil )
        #expect( profileRouter.viewStack.count == 1 )
        #expect( profileRouter.viewStack.last?.path.Typed( TestSecurePath.self ) != nil )
    }

    @Test
    func TabUniqueClassMatchesAnExistingRootByPathType() throws
    {
        let router = MakeRouter()
        router.Route( TestTabsPath() )
        let tabsEntry = try #require( router.viewStack.last )
        let descriptors = [
            RouterTabDescriptor( id: "home", index: 0, title: "Home", rootPath: TestTabAPath() ),
            RouterTabDescriptor( id: "settings", index: 1, title: "Settings", rootPath: TestSettingsPath( section: "root" ) )
        ]
        let tabs = router.CreateTabs( viewKey: tabsEntry.id, descriptors: descriptors, tabUnique: .class )

        for descriptor in descriptors
        {
            tabs.Route( descriptor.index, path: descriptor.rootPath, recreate: false )
        }

        let routed = tabs.Router( for: 0 ).Route( TestSettingsPath( section: "other" ) )

        #expect( (routed as? RouterTabSimple) === tabs.Router( for: 1 ) )
        #expect( tabs.tabIndex == 1 )
        #expect( tabs.Router( for: 0 ).viewStack.count == 1 )
        #expect( tabs.Router( for: 1 ).viewStack.last?.path.Typed( TestSettingsPath.self )?.section == "root" )
    }

    @Test
    func TabUniqueEqualMatchesOnlyAnEqualExistingRoot() throws
    {
        let router = MakeRouter()
        router.Route( TestTabsPath() )
        let tabsEntry = try #require( router.viewStack.last )
        let descriptors = [
            RouterTabDescriptor( id: "home", index: 0, title: "Home", rootPath: TestTabAPath() ),
            RouterTabDescriptor( id: "settings", index: 1, title: "Settings", rootPath: TestSettingsPath( section: "root" ) )
        ]
        let tabs = router.CreateTabs( viewKey: tabsEntry.id, descriptors: descriptors, tabUnique: .equal )

        for descriptor in descriptors
        {
            tabs.Route( descriptor.index, path: descriptor.rootPath, recreate: false )
        }

        let routed = tabs.Router( for: 0 ).Route( TestSettingsPath( section: "root" ) )

        #expect( (routed as? RouterTabSimple) === tabs.Router( for: 1 ) )
        #expect( tabs.tabIndex == 1 )

        #expect( tabs.Route( 0 ) )
        tabs.Router( for: 0 ).Route( TestSettingsPath( section: "other" ) )

        #expect( tabs.tabIndex == 0 )
        #expect( tabs.Router( for: 0 ).viewStack.count == 2 )
        #expect( tabs.Router( for: 0 ).viewStack.last?.path.Typed( TestSettingsPath.self )?.section == "other" )
        #expect( tabs.Router( for: 1 ).viewStack.last?.path.Typed( TestSettingsPath.self )?.section == "root" )
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

    @Test
    func NavigationBarHiddenIsEntryBound() throws
    {
        let router = MakeRouter()
        router.Route( TestHomePath() )
        router.Route( TestSettingsPath( section: "next" ) )

        let firstEntry = try #require( router.viewStack.first )
        let secondEntry = try #require( router.viewStack.last )
        let store = RouterNavigationBarStore()
        let provider = AnyRouterNavigationBarProvider( configuration: "Default" ) {
            configuration, _ in

            Text( configuration )
        }
        let token = UUID()

        store.SetHidden( entryID: firstEntry.id, token: token )

        #expect( IsHidden( store.Resolve( provider: provider, entry: firstEntry, context: NavigationBarContext( firstEntry ) ) ) )
        #expect( IsCustom( store.Resolve( provider: provider, entry: secondEntry, context: NavigationBarContext( secondEntry ) ) ) )

        store.RemoveHidden( entryID: firstEntry.id, token: token )

        #expect( IsCustom( store.Resolve( provider: provider, entry: firstEntry, context: NavigationBarContext( firstEntry ) ) ) )
    }

    @Test
    func NavigationBarResolutionPrecedence() throws
    {
        let router = MakeRouter()
        router.Route( TestHomePath() )

        let entry = try #require( router.viewStack.last )
        let store = RouterNavigationBarStore()
        let provider = AnyRouterNavigationBarProvider( configuration: "Default" ) {
            configuration, _ in

            Text( configuration )
        }
        let nativeToken = UUID()
        let hiddenToken = UUID()
        let replacementToken = UUID()
        let context = NavigationBarContext( entry )

        #expect( IsNative( store.Resolve( provider: nil, entry: entry, context: context ) ) )
        #expect( IsCustom( store.Resolve( provider: provider, entry: entry, context: context ) ) )

        store.SetNative( entryID: entry.id, token: nativeToken )
        #expect( IsNative( store.Resolve( provider: provider, entry: entry, context: context ) ) )

        store.SetHidden( entryID: entry.id, token: hiddenToken )
        #expect( IsHidden( store.Resolve( provider: provider, entry: entry, context: context ) ) )

        store.SetReplacement( entryID: entry.id, token: replacementToken ) {
            AnyView( Text( "Replacement" ) )
        }
        #expect( IsCustom( store.Resolve( provider: provider, entry: entry, context: context ) ) )

        store.RemoveReplacement( entryID: entry.id, token: replacementToken )
        store.RemoveHidden( entryID: entry.id, token: hiddenToken )
        store.RemoveNative( entryID: entry.id, token: nativeToken )

        #expect( IsCustom( store.Resolve( provider: provider, entry: entry, context: context ) ) )
    }

    @Test
    func NavigationBarContentSpacingUsesEntryUpdates() throws
    {
        let router = MakeRouter()
        router.Route( TestHomePath() )
        router.Route( TestSettingsPath( section: "next" ) )

        let firstEntry = try #require( router.viewStack.first )
        let secondEntry = try #require( router.viewStack.last )
        let store = RouterNavigationBarStore()
        let provider = AnyRouterNavigationBarProvider(
            configuration: TestNavigationBarConfiguration( contentSpacing: 8 ),
            contentSpacing: { $0.contentSpacing } ) {
                _, _ in

                EmptyView()
            }
        let token = UUID()

        store.SetUpdate( entryID: firstEntry.id, token: token, update: AnyRouterNavigationBarUpdate {
            (configuration: inout TestNavigationBarConfiguration) in

            configuration.contentSpacing = 16
        } )

        #expect( ContentSpacing( store.Resolve( provider: provider, entry: firstEntry, context: NavigationBarContext( firstEntry ) ) ) == 16 )
        #expect( ContentSpacing( store.Resolve( provider: provider, entry: secondEntry, context: NavigationBarContext( secondEntry ) ) ) == 8 )

        let replacementToken = UUID()
        store.SetReplacement( entryID: firstEntry.id, token: replacementToken ) {
            AnyView( EmptyView() )
        }

        #expect( ContentSpacing( store.Resolve( provider: provider, entry: firstEntry, context: NavigationBarContext( firstEntry ) ) ) == 16 )

        store.RemoveReplacement( entryID: firstEntry.id, token: replacementToken )

        store.RemoveUpdate( entryID: firstEntry.id, token: token )

        #expect( ContentSpacing( store.Resolve( provider: provider, entry: firstEntry, context: NavigationBarContext( firstEntry ) ) ) == 8 )
    }

    @Test
    func NavigationBarContentSpacingDefaultsToZero() throws
    {
        let router = MakeRouter()
        router.Route( TestHomePath() )

        let entry = try #require( router.viewStack.last )
        let provider = AnyRouterNavigationBarProvider( configuration: "Default" ) {
            configuration, _ in

            Text( configuration )
        }

        #expect( ContentSpacing( RouterNavigationBarStore().Resolve(
            provider: provider,
            entry: entry,
            context: NavigationBarContext( entry ) ) ) == 0 )
    }

    @Test
    func NavigationBarContentPlacementUsesEntryUpdates() throws
    {
        let router = MakeRouter()
        router.Route( TestHomePath() )
        router.Route( TestSettingsPath( section: "next" ) )

        let firstEntry = try #require( router.viewStack.first )
        let secondEntry = try #require( router.viewStack.last )
        let store = RouterNavigationBarStore()
        let provider = AnyRouterNavigationBarProvider(
            configuration: TestNavigationBarConfiguration( contentSpacing: 0 ),
            contentPlacement: { $0.contentPlacement } ) {
                _, _ in

                EmptyView()
            }
        let updateToken = UUID()

        store.SetUpdate( entryID: firstEntry.id, token: updateToken, update: AnyRouterNavigationBarUpdate {
            (configuration: inout TestNavigationBarConfiguration) in

            configuration.contentPlacement = .overlay
        } )

        #expect( ContentPlacement( store.Resolve( provider: provider, entry: firstEntry, context: NavigationBarContext( firstEntry ) ) ) == .overlay )
        #expect( ContentPlacement( store.Resolve( provider: provider, entry: secondEntry, context: NavigationBarContext( secondEntry ) ) ) == .inset( spacing: 8 ) )

        let replacementToken = UUID()
        store.SetReplacement( entryID: firstEntry.id, token: replacementToken ) {
            AnyView( EmptyView() )
        }

        #expect( ContentPlacement( store.Resolve( provider: provider, entry: firstEntry, context: NavigationBarContext( firstEntry ) ) ) == .overlay )
    }

    private func NavigationBarContext( _ entry: RouteEntry ) -> RouterNavigationBarContext
    {
        RouterNavigationBarContext( entry: entry, canGoBack: false, back: {} )
    }

    private func IsCustom( _ resolution: RouterNavigationBarResolution ) -> Bool
    {
        if case .custom = resolution
        {
            return true
        }

        return false
    }

    private func IsNative( _ resolution: RouterNavigationBarResolution ) -> Bool
    {
        if case .native = resolution
        {
            return true
        }

        return false
    }

    private func IsHidden( _ resolution: RouterNavigationBarResolution ) -> Bool
    {
        if case .hidden = resolution
        {
            return true
        }

        return false
    }

    private func ContentSpacing( _ resolution: RouterNavigationBarResolution ) -> CGFloat?
    {
        if case .custom( _, .inset( let contentSpacing ) ) = resolution
        {
            return contentSpacing
        }

        return nil
    }

    private func ContentPlacement( _ resolution: RouterNavigationBarResolution ) -> RouterNavigationBarContentPlacement?
    {
        if case .custom( _, let contentPlacement ) = resolution
        {
            return contentPlacement
        }

        return nil
    }

    private func MakeRouter(   ) -> RouterSimple
    {
        RouterSimple(    registry: GeneratedRouteRegistry.Make(   ) )
    }
}
