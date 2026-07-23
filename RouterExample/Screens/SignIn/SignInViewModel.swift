import RouterSwiftUI

final class SignInViewModel: RouterViewModel
{
    private let next: RouteParams
    
    init( next: RouteParams )
    {
        self.next = next
    }
    
    func OnShowConfirm()
    {
        router.Route( SignConfirmPath( next: next ) )
    }
}
