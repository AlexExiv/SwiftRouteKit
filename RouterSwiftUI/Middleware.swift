import Foundation

@MainActor
public protocol MiddlewareController: AnyObject
{
    init()

    func OnBeforeRoute( router: any Router, current: AnyRoutePath, next: RouteParams ) -> Bool
    func OnRoute( router: any Router, previous: AnyRoutePath?, next: RouteParams ) -> Bool
    func OnClose( router: any Router, current: AnyRoutePath, previous: AnyRoutePath? ) -> Bool
}

public extension MiddlewareController
{
    func OnBeforeRoute( router: any Router, current: AnyRoutePath, next: RouteParams ) -> Bool
    {
        false
    }

    func OnRoute( router: any Router, previous: AnyRoutePath?, next: RouteParams ) -> Bool
    {
        false
    }

    func OnClose( router: any Router, current: AnyRoutePath, previous: AnyRoutePath? ) -> Bool
    {
        false
    }
}

public struct GlobalMiddlewareRegistration
{
    public let order: Int
    let factory: @MainActor () -> any MiddlewareController
    let typeName: String

    @MainActor
    public init( _ type: ( any MiddlewareController.Type ), order: Int )
    {
        self.order = order
        self.typeName = String( reflecting: type )
        self.factory = { type.init() }
    }
}
