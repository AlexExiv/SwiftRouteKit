import RouterSwiftUI

struct SignUpPath: RoutePath
{
    let next: RouteParams
    
    init( next: RouteParams )
    {
        self.next = next
    }
}

@Route( uri: "/sign-up" )
final class SignUpRouteController: RouteControllerVM<SignUpPath, SignUpViewModel, SignUpView>
{
    override func OnCreateViewModel( path: SignUpPath ) -> SignUpViewModel
    {
        SignUpViewModel(
            next: path.next,
            authService: FlowerDependencyContainer.shared.authService
        )
    }
}
