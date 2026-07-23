import RouterSwiftUI

final class SignConfirmViewModel: RouterViewModel
{
    private let next: RouteParams
    
    init( next: RouteParams )
    {
        self.next = next
    }
    
    func OnShowSignUp()
    {
        router.Route( SignUpPath( next: next ) )
    }
}
