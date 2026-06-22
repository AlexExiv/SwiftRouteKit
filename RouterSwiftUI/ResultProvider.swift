import Foundation

@MainActor
public final class ResultProvider
{
    public let key: String

    private let resultBinding: RouteResultBinding?

    public convenience init( key: String )
    {
        self.init( key: key, dispatcher: Self.EmptyDispatcher )
    }

    public convenience init( key: String, dispatcher: @escaping ( Any ) -> Void )
    {
        self.init(
            key: key,
            resultBinding: RouteResultBinding( onDispatch: {
                dispatcher( $0 )
                return false
            } ) )
    }

    init( key: String, resultBinding: RouteResultBinding? )
    {
        self.key = key
        self.resultBinding = resultBinding
    }

    public func Send<Result>( _ result: Result )
    {
        resultBinding?.Dispatch( result )
    }

    private static func EmptyDispatcher( _ value: Any )
    {
    }
}

public final class RouteResultBinding: Hashable
{
    private let onDispatch: (Any) -> Bool
    private let onComplete: () -> Void
    private var isCompleted = false

    public init<Result>( _ handler: @escaping (Result) -> Void )
    {
        onDispatch = {
            guard let result = $0 as? Result else { return false }

            handler( result )
            return false
        }
        onComplete = {}
    }

    init( onDispatch: @escaping (Any) -> Bool, onComplete: @escaping () -> Void = {} )
    {
        self.onDispatch = onDispatch
        self.onComplete = onComplete
    }

    deinit
    {
        Complete()
    }

    func Dispatch( _ value: Any )
    {
        guard isCompleted == false else { return }

        if onDispatch( value )
        {
            isCompleted = true
        }
    }

    func Complete()
    {
        guard isCompleted == false else { return }

        isCompleted = true
        onComplete()
    }

    public static func == ( lhs: RouteResultBinding, rhs: RouteResultBinding ) -> Bool
    {
        lhs === rhs
    }

    public func hash( into hasher: inout Hasher )
    {
        hasher.combine( ObjectIdentifier( self ) )
    }
}
