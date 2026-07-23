import SwiftUI
import RouterSwiftUI

struct SignInView: RouterFullScreenView
{
    @Environment( \.router ) private var router
    
    private let path: SignInPath
    private let authService: AuthServiceProtocol
    
    init( path: SignInPath, authService: AuthServiceProtocol )
    {
        self.path = path
        self.authService = authService
    }
    
    var body: some View
    {
        Button( "Авторизоваться" )
        {
            authService.login()
            router.Close()?.Route( path.next )
        }
        .buttonStyle( .borderedProminent )
        .controlSize( .large )
        .frame( maxWidth: .infinity, maxHeight: .infinity )
        //.topAppBarTitle( "Авторизация" )
    }
}

#Preview
{
    SignInView(
        path: SignInPath( next: RouteParams( path: CartPath() ) ),
        authService: AuthService()
    )
}
