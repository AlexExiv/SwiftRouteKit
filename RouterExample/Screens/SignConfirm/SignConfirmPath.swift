import RouterSwiftUI

struct SignConfirmPath: RoutePath
{
    let next: RouteParams
    
    init( next: RouteParams )
    {
        self.next = next
    }
}

@Route( uri: "/sign-confirm" )
final class SignConfirmRouteController: RouteControllerVM<SignConfirmPath, SignConfirmViewModel, SignConfirmView>
{
    override func OnCreateViewModel( path: SignConfirmPath ) -> SignConfirmViewModel
    {
        SignConfirmViewModel( next: path.next )
    }
}
