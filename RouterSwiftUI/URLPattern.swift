import Foundation

public struct RouteURLMatch: Sendable
{
    public let parameters: [String: String]
    public let query: [String: String]
}

public struct RouteURLPattern: Sendable
{
    public let rawValue: String
    public let parameterNames: [String]

    private let segments: [Segment]

    public init( _ rawValue: String ) throws
    {
        guard rawValue.isEmpty == false, rawValue.first == "/" else
        {            throw RouterError.invalidURI( rawValue )
        }

        var names = [String]()
        var parsedSegments = [Segment]()
        let path = rawValue.split( separator: "?", maxSplits: 1 ).first.map( String.init ) ?? rawValue

        for segment in path.split( separator: "/" )
        {
            let value = String( segment )
            if value.hasPrefix( ":" )
            {
                let name = String( value.dropFirst() )
                guard name.isEmpty == false, names.contains( name ) == false else
                {                    throw RouterError.invalidURI( rawValue )
                }

                names.append( name )
                parsedSegments.append( .parameter( name ) )
            }
            else
            {
                parsedSegments.append( .literal( value ) )
            }
        }

        self.rawValue = rawValue
        self.parameterNames = names
        self.segments = parsedSegments
    }

    public func Match( _ url: String ) -> RouteURLMatch?
    {
        let components = URLComponents( string: url )
        let path = components?.path ?? url.split( separator: "?", maxSplits: 1 ).first.map( String.init ) ?? url
        let actualSegments = path.split( separator: "/" ).map( String.init )

        guard actualSegments.count == segments.count else { return nil }

        var parameters = [String: String]()
        for ( pattern, actual ) in zip( segments, actualSegments )
        {
            switch pattern
            {
            case .literal( let value ):
                guard value == actual.removingPercentEncoding ?? actual else { return nil }
            case .parameter( let name ):
                parameters[name] = actual.removingPercentEncoding ?? actual
            }
        }

        var query = [String: String]()
        components?.queryItems?.forEach {
            query[$0.name] = $0.value ?? ""
        }

        return RouteURLMatch( parameters: parameters, query: query )
    }

    public func Matches( _ url: String ) -> Bool
    {
        Match( url ) != nil
    }

    private enum Segment: Sendable
    {
        case literal( String )
        case parameter( String )
    }
}
