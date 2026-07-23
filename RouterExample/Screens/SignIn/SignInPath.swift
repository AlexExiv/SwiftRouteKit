import RouterSwiftUI

struct SignInPath: RoutePath
{
    let next: RouteParams
    
    init( next: RouteParams )
    {
        self.next = next
    }
}

@Route( uri: "/sign-in" )
final class SignInRouteController: RouteController<SignInPath, SignInView>
{
    override func OnCreateView( path: SignInPath ) -> SignInView
    {
        SignInView(
            path: path,
            authService: FlowerDependencyContainer.shared.authService
        )
    }
}
