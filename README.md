# RouterSwiftUI

SwiftUI routing library with generated route registry, Android Router-like route logic, `RouteController`, middleware, `singleTop`, result support, and SwiftUI hosts based on `NavigationStack`, `TabView`, `.sheet`, and `.fullScreenCover`.

Main user flow:

```swift
router.Route( ProfilePath( id: 42 ) )
```

The transition style is defined by the created view type:

- `RouterView` -> push in `NavigationStack`
- `RouterDialogView` -> dialog-like `.sheet`
- `RouterBottomSheetView` -> `.sheet` with `presentationDetents`
- `RouterFullScreenView` -> `.fullScreenCover`
- `RouterTabsView` -> tabs with child routers

## Requirements

- iOS 16+
- Xcode 15+
- Swift 5.9+
- Swift Package Manager

## Add The Library

Attach the generator plugin to every target that contains `@Route`, `@UseMiddlewares`, or `@GlobalMiddleware`.

### Option A: Xcode Target

1. Add `RouterSwiftUI` through `File -> Add Package Dependencies...`.
2. Link the `RouterSwiftUI` library product to the app target.
3. Open the app target `Build Phases`.
4. In `Run Build Tool Plug-ins`, add `RouterSwiftUIGeneratorPlugin`.
5. If Xcode asks to trust the plugin, allow it.

```swift
@main
struct MyApp: App
{
    @State
    private var router = RouterFactory.Make( registry: GeneratedRouteRegistry.Make() )

    var body: some Scene
    {
        WindowGroup
        {
            RouterHost( router: router, rootPath: HomePath() )
        }
    }
}
```

### Option B: SwiftPM Target

Add the package and plugin in `Package.swift`.

```swift
// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
        .iOS( .v16 )
    ],
    dependencies: [
        .package( url: "https://github.com/your-org/RouterSwiftUI.git", from: "0.1.0" )
    ],
    targets: [
        .target(
            name: "MyApp",
            dependencies: [
                .product( name: "RouterSwiftUI", package: "RouterSwiftUI" )
            ],
            plugins: [
                .plugin( name: "RouterSwiftUIGeneratorPlugin", package: "RouterSwiftUI" )
            ] )
    ]
)
```

For local development:

```swift
.package( path: "../RouterSwiftUI" )
```

### Plugin Output

On build/rebuild, the plugin generates `GeneratedRouteRegistry` for the target that owns the annotated route controllers.

```swift
let registry = GeneratedRouteRegistry.Make()
let router = RouterFactory.Make( registry: registry )
```

Do not add `GeneratedRouteRegistry.swift` as a checked-in source file. It is plugin output.

If you open `RouterSwiftUI.xcodeproj`, SwiftPM-only folders such as `RouterSwiftUIGenerator`, `RouterSwiftUIGeneratorPlugin`, and `RouterSwiftUIMacros` may not appear in the Xcode project navigator. They are still part of the package through `Package.swift`. Open `Package.swift` directly to see all Swift Package targets.

## Bootstrap

Create a router from the generated registry and render it with `RouterHost`.

```swift
import SwiftUI
import RouterSwiftUI

@main
struct MyApp: App
{
    @State
    private var router = RouterFactory.Make( registry: GeneratedRouteRegistry.Make() )

    var body: some Scene
    {
        WindowGroup
        {
            RouterHost( router: router, rootPath: HomePath() )
        }
    }
}
```

Inside SwiftUI views, use the router from environment:

```swift
struct HomeView: RouterView
{
    @Environment( \.router )
    private var router

    var body: some View
    {
        Button( "Open profile" )
        {
            router.Route( ProfilePath( id: 42 ) )
        }
    }
}
```

## Router API

Most navigation starts from a strongly typed `RoutePath`.

```swift
router.Route( ProfilePath( id: 42 ) )
router.Replace( ProfilePath( id: 7 ) )
router.Back()
router.Close()
router.CloseToTop()
```

Open deeplinks through the generated registry:

```swift
router.Route( url: "/profile/42?source=push" )
```

Route with a result callback:

```swift
router.RouteWithResult( EditProfilePath( id: 42 ) ) { result in
    print( "Profile changed: \(result)" )
}
```

The router owns route logic only. SwiftUI state lives in `RouterHost` through `SwiftUINavigator`, and commands are delivered through `CommandBuffer` and `SwiftUICommandExecutor`.

## RoutePath

Route paths are immutable route inputs. Mutable screen state should live in a view model.

```swift
import RouterSwiftUI

struct HomePath: RoutePath, EmptyParamsPath
{
    init()
    {
    }
}

struct ProfilePath: RoutePath
{
    let id: Int

    init( id: Int )
    {
        self.id = id
    }
}
```

`EmptyParamsPath` is only for paths that should be opened from a deeplink with no path parameters and can be created as `Path()`. For routes with parameters, keep the path plain and convert URL maps in the controller.

Use `RouteController.Convert( path:query:)` when a route should be opened from a deeplink URL with parameters.

```swift
@Route( uri: "/profile/:id", singleTop: .class )
final class ProfileRouteController: RouteControllerVM<ProfilePath, ProfileViewModel, ProfileView>
{
    override func Convert( path: [String: String], query: [String: String] ) -> ProfilePath?
    {
        guard let id = Int( path["id"] ?? "" ) else { return nil }

        return ProfilePath( id: id )
    }
}
```

If `Convert( path:query:)` returns `nil`, routing by URL fails because the route cannot be built.

## RouteController

Use `RouteController<Path, View>` for a screen without a router-owned view model.

If the view can be created with `View()`, the controller can be empty. `@Route` generates `OnCreateView( path:)` automatically.

```swift
import SwiftUI
import RouterSwiftUI

struct AboutPath: RoutePath, EmptyParamsPath
{
    init()
    {
    }
}

struct AboutView: RouterView
{
    var body: some View
    {
        Text( "About" )
            .navigationTitle( "About" )
    }
}

@Route( uri: "/about", singleTop: .equal )
final class AboutRouteController: RouteController<AboutPath, AboutView>
{
}
```

If the view needs values from `path`, implement `OnCreateView( path:)` manually. In that case `@Route` does not generate it.

```swift
struct SettingsPath: RoutePath
{
    let section: String
}

struct SettingsView: RouterView
{
    let section: String

    var body: some View
    {
        Text( "Settings: \(section)" )
            .navigationTitle( "Settings" )
    }
}

@Route( uri: "/settings", singleTop: .equal )
final class SettingsRouteController: RouteController<SettingsPath, SettingsView>
{
    override func OnCreateView( path: SettingsPath ) -> SettingsView
    {
        SettingsView( section: path.section )
    }
}
```

`@Route` arguments:

- `uri`: deeplink pattern. Supports path parameters like `/profile/:id` and query parameters.
- `singleTop: .none`: always creates a new entry.
- `singleTop: .class`: closes back to an existing entry with the same path type.
- `singleTop: .equal`: closes back to an existing entry with an equal path value.
- `animation`: optional `AnimationController` type. SwiftUI falls back gracefully where per-route customization is limited.

Route controller hooks:

```swift
override func OnBeforeRoute( router: any Router, current: SettingsPath, next: RouteParams ) -> Bool
{
    false
}

override func OnRouteTo( router: any Router, previous: AnyRoutePath?, next: RouteParams ) -> Bool
{
    false
}

override func OnClose( router: any Router, current: SettingsPath, previous: AnyRoutePath? ) -> Bool
{
    false
}
```

## RouteControllerVM

Use `RouteControllerVM<Path, VM, View>` when the router should create and keep a view model for a route entry.

The view model is created before the SwiftUI view and then passed into the view initializer. Its lifecycle is bound to `RouteEntry`, not SwiftUI view recreation.

If `VM()` and `View( viewModel:)` are valid, the controller can be empty. `@Route` generates both methods.

```swift
import SwiftUI
import RouterSwiftUI

final class ProfileViewModel: RouterViewModel
{
    @Published
    var title = ""

    func Configure( id: Int )
    {
        title = "Profile \(id)"
    }

    override func OnRouterBound()
    {
        // Called once when the RouteEntry is bound to Router.
        // `router` and `resultProvider` are available here.
    }
}

struct ProfileView: RouterView
{
    @ObservedObject
    var viewModel: ProfileViewModel

    var body: some View
    {
        Text( viewModel.title )
            .navigationTitle( viewModel.title )
    }
}

@Route( uri: "/profile/:id", singleTop: .class )
final class ProfileRouteController: RouteControllerVM<ProfilePath, ProfileViewModel, ProfileView>
{
    override func Convert( path: [String: String], query: [String: String] ) -> ProfilePath?
    {
        guard let id = Int( path["id"] ?? "" ) else { return nil }

        return ProfilePath( id: id )
    }
}
```

If one of the defaults is not enough, implement only the method you need. The macro generates only missing methods.

```swift
@Route( uri: "/profile/:id", singleTop: .class )
final class ProfileRouteController: RouteControllerVM<ProfilePath, ProfileViewModel, ProfileView>
{
    override func OnCreateViewModel( path: ProfilePath ) -> ProfileViewModel
    {
        let viewModel = ProfileViewModel()
        viewModel.Configure( id: path.id )
        return viewModel
    }
}
```

## Presentation By View Type

Push screen:

```swift
struct ProfileView: RouterView
{
    var body: some View { Text( "Profile" ) }
}
```

Dialog:

```swift
struct ConfirmDialogView: RouterDialogView
{
    var body: some View { Text( "Confirm" ).padding() }
}
```

Bottom sheet:

```swift
struct FiltersSheetView: RouterBottomSheetView
{
    static let routerPresentationDetents: Set<PresentationDetent> = [.medium, .large]

    var body: some View { Text( "Filters" ).padding() }
}
```

Full screen:

```swift
struct OnboardingView: RouterFullScreenView
{
    var body: some View { Text( "Onboarding" ) }
}
```

## Local Middleware

Use `@UseMiddlewares( ... )` on a route controller. Local middleware runs in the same order as the arguments.

```swift
import RouterSwiftUI

struct LoginPath: RoutePath, EmptyParamsPath
{
    init()
    {
    }
}

final class AuthMiddleware: MiddlewareController
{
    static var isAuthorized = false

    init()
    {
    }

    func OnRoute( router: any Router, previous: AnyRoutePath?, next: RouteParams ) -> Bool
    {
        guard next.path.Typed( ProfilePath.self ) != nil, Self.isAuthorized == false else { return false }

        router.Route( LoginPath() )
        return true
    }
}

@Route( uri: "/profile/:id", singleTop: .class )
@UseMiddlewares( AuthMiddleware.self )
final class ProfileRouteController: RouteControllerVM<ProfilePath, ProfileViewModel, ProfileView>
{
    override func Convert( path: [String: String], query: [String: String] ) -> ProfilePath?
    {
        guard let id = Int( path["id"] ?? "" ) else { return nil }

        return ProfilePath( id: id )
    }
}
```

Middleware callbacks:

- `OnBeforeRoute`: called on the current route before leaving it.
- `OnRoute`: called on the target route before opening it.
- `OnClose`: called before closing the current route.

Return `true` to stop the current navigation. This is useful when middleware redirects to another route.

## Global Middleware

Annotate a middleware class with `@GlobalMiddleware( order: 0 )`. Global middleware runs after route controller hooks and local middleware, sorted by `order`.

```swift
@GlobalMiddleware( order: 0 )
final class AnalyticsMiddleware: MiddlewareController
{
    init()
    {
    }

    func OnRoute( router: any Router, previous: AnyRoutePath?, next: RouteParams ) -> Bool
    {
        print( "Open route: \(next.path.typeName)" )
        return false
    }
}
```

Execution order:

1. `RouteController` hook
2. Local middleware from `@UseMiddlewares( ... )`
3. Global middleware from `@GlobalMiddleware( order: 0 )`

## Tabs

Each tab has its own child `Router` and its own `RouterHost`/`NavigationStack`.

```swift
struct MainTabsView: RouterTabsView
{
    var body: some View
    {
        RouterTabsHost( descriptors: [
            RouterTabDescriptor( id: "feed", index: 0, title: "Feed", systemImage: "list.bullet", rootPath: FeedPath() ),
            RouterTabDescriptor( id: "search", index: 1, title: "Search", systemImage: "magnifyingglass", rootPath: SearchPath() )
        ] )
    }
}

@Route( uri: "/tabs" )
final class MainTabsRouteController: RouteController<MainTabsPath, MainTabsView>
{
}
```

## Generated Registry

The build plugin scans source files for:

- `@Route`
- `@UseMiddlewares`
- `@GlobalMiddleware`

It generates `GeneratedRouteRegistry` in the target that uses the plugin.

```swift
let registry = GeneratedRouteRegistry.Make()
let router = RouterFactory.Make( registry: registry )
```

Build-time checks include duplicate URI, duplicate `RoutePath` registration, invalid URI pattern, and invalid controller shape where possible.

## Source Layout

Runtime API lives in:

```text
RouterSwiftUI/
```

Macro declarations and implementation:

```text
RouterSwiftUI/Annotations.swift
RouterSwiftUIMacros/RouterSwiftUIMacros.swift
```

Build tool plugin and generator:

```text
RouterSwiftUIGeneratorPlugin/RouterSwiftUIGeneratorPlugin.swift
RouterSwiftUIGenerator/main.swift
```

Sample routes:

```text
RouterSwiftUISample/SampleRoutes.swift
```
