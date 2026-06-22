import Foundation

public struct RouterStackPathComponent: Identifiable, Hashable
{
    public let id: String
    public let routerKey: String

    public init( id: String, routerKey: String )
    {
        self.id = id
        self.routerKey = routerKey
    }
}

@MainActor
public final class RouterStack
{
    public private( set ) var entries: [RouterStackEntry] = []

    public init()
    {
    }

    public func Push( viewKey: String, routerKey: String )
    {
        entries.append( .single( RouterStackPathComponent( id: viewKey, routerKey: routerKey ) ) )
    }

    public func PushReel( viewKey: String )
    {
        guard entries.contains( where: { $0.viewKey == viewKey } ) else { return }

        entries.append( .reel( RouterStackReel( viewKey: viewKey ) ) )
    }

    public func SwitchReel( viewKey: String, index: Int )
    {
        guard case .reel( let reel ) = entries.last( where: { $0.viewKey == viewKey } ) else { return }

        reel.currentIndex = index
    }

    public func Remove( viewKey: String )
    {
        entries.removeAll { $0.Remove( viewKey: viewKey ) }
    }
}

public enum RouterStackEntry
{
    case single( RouterStackPathComponent )
    case reel( RouterStackReel )

    public var viewKey: String
    {
        switch self
        {
        case .single( let component ):
            return component.id
        case .reel( let reel ):
            return reel.viewKey
        }
    }

    fileprivate func Remove( viewKey: String ) -> Bool
    {
        switch self
        {
        case .single( let component ):
            return component.id == viewKey
        case .reel( let reel ):
            reel.Remove( viewKey: viewKey )
            return reel.viewKey == viewKey
        }
    }
}

public final class RouterStackReel
{
    public let viewKey: String
    public var currentIndex: Int = 0
    public private( set ) var stacks = [Int: [RouterStackPathComponent]]()

    init( viewKey: String )
    {
        self.viewKey = viewKey
    }

    public func Push( viewKey: String, routerKey: String, index: Int )
    {
        stacks[index, default: []].append( RouterStackPathComponent( id: viewKey, routerKey: routerKey ) )
    }

    public func Remove( viewKey: String )
    {
        for key in stacks.keys
        {
            stacks[key]?.removeAll { $0.id == viewKey }
        }
    }
}
