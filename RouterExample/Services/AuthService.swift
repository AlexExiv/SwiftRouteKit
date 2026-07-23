import Combine

protocol AuthServiceProtocol: AnyObject
{
    var isLogin: CurrentValueSubject<Bool, Never> { get }
    
    func login()
}

final class AuthService: AuthServiceProtocol
{
    let isLogin = CurrentValueSubject<Bool, Never>( false )
    
    func login()
    {
        isLogin.value = true
    }
}
