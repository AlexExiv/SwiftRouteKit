import SwiftUI
import RouterSwiftUI

struct SignUpView: RouterView
{
    @ObservedObject var viewModel: SignUpViewModel
    
    var body: some View
    {
        VStack( spacing: 0 )
        {
            GeometryReader
            {
                proxy in

                Color.blue
                    .frame( maxWidth: .infinity )
                    .frame( height: proxy.safeAreaInsets.top + 80 )
                    .ignoresSafeArea( edges: .top )
            }
            .frame( height: 80 )

            Button( "Зарегистрироваться" )
            {
                viewModel.OnSignUp()
            }
            .buttonStyle( .borderedProminent )
            .controlSize( .large )
            .frame( maxWidth: .infinity, maxHeight: .infinity )
        }
        .topAppBarTransparent()
    }
}

#Preview
{
    SignUpView( viewModel: SignUpViewModel(
        next: RouteParams( path: CartPath() ),
        authService: AuthService()
    ) )
}
