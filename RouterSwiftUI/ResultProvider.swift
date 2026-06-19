import Foundation

@MainActor
public final class ResultProvider
{
    public let key: String

    private let dispatcher: (Any) -> Void

    public convenience init( key: String )
    {
        self.init( key: key, dispatcher: Self.EmptyDispatcher )
    }

    public init( key: String, dispatcher: @escaping ( Any ) -> Void )
    {
        self.key = key
        self.dispatcher = dispatcher
    }

    public func Send<Result>( _ result: Result )
    {
        dispatcher( result )
    }

    private static func EmptyDispatcher( _ value: Any )
    {
    }
}

@MainActor
public struct RouteResultBinding
{
    let Dispatch: (Any) -> Void

    public init<Result>( _ handler: @escaping (Result) -> Void )
    {
        Dispatch = {
            guard let result = $0 as? Result else { return }

            handler( result )
        }
    }
}
