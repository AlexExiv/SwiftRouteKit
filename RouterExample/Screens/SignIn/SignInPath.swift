import RouterSwiftUI

struct SignInPath: RoutePath
{
    let next: RouteParams
    
    init( next: RouteParams )
    {
        self.next = next
    }
}

@Chain( SignConfirmPath.self, SignUpPath.self )
@Route( uri: "/sign-in" )
final class SignInRouteController: RouteControllerVM<SignInPath, SignInViewModel, SignInView>
{
    override func OnCreateViewModel( path: SignInPath ) -> SignInViewModel
    {
        SignInViewModel( next: path.next )
    }
}
