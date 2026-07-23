import RouterSwiftUI

final class SignUpViewModel: RouterViewModel
{
    private let next: RouteParams
    private let authService: AuthServiceProtocol
    
    init( next: RouteParams, authService: AuthServiceProtocol )
    {
        self.next = next
        self.authService = authService
    }
    
    func OnSignUp()
    {
        authService.login()
        router.Close()?.Route( next )
    }
}
