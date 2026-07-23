import RouterSwiftUI
import Combine

final class AuthMiddleware: MiddlewareController
{
    init()
    {
    }
    
    func OnRoute( router: any Router, previous: AnyRoutePath?, next: RouteParams ) -> Bool
    {
        guard FlowerDependencyContainer.shared.authService.isLogin.value == false else { return false }
        
        router.Route( SignInPath( next: next ) )
        return true
    }
}
