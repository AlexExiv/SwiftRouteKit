import SwiftUI
import RouterSwiftUI

struct SignConfirmView: RouterView
{
    @ObservedObject var viewModel: SignConfirmViewModel
    
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

            Button( "Подтвердить" )
            {
                viewModel.OnShowSignUp()
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
    SignConfirmView( viewModel: SignConfirmViewModel(
        next: RouteParams( path: CartPath() )
    ) )
}
