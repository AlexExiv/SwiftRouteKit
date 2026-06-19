import Foundation

@MainActor
public enum RouterCommand
{
    case setRoot( RouteEntry )
    case push( RouteEntry )
    case replace( RouteEntry, replacing: String? )
    case presentDialog( RouteEntry )
    case presentBottomSheet( RouteEntry )
    case presentFullScreen( RouteEntry )
    case close( RouteEntry? )
    case closeTo( String )
    case closeAll
    case selectTab( viewKey: String, index: Int )

    var viewKey: String?
    {
        switch self
        {
        case .setRoot( let entry ),
             .push( let entry ),
             .replace( let entry, _ ),
             .presentDialog( let entry ),
             .presentBottomSheet( let entry ),
             .presentFullScreen( let entry ):
            return entry.id
        case .close, .closeTo, .closeAll, .selectTab:
            return nil
        }
    }
}

@MainActor
public protocol CommandExecutor: AnyObject
{
    func Execute( _ command: RouterCommand )
    func Sync( entries: [String] ) -> [String]
}

@MainActor
public final class CommandBuffer
{
    private var executor: ( any CommandExecutor )?
    private var buffer = [RouterCommand]()

    public init()
    {
    }

    public func Bind( executor: any CommandExecutor )
    {
        self.executor = executor
        Flush()
    }

    public func Unbind()
    {
        executor = nil
    }

    public func Apply( _ command: RouterCommand )
    {
        guard let executor else
        {
            buffer.append( command )
            return
        }

        executor.Execute( command )
    }

    public func Sync( entries: [String] ) -> [String]
    {
        guard let executor else { return [] }

        var removed = executor.Sync( entries: entries )
        for command in buffer
        {
            guard let key = command.viewKey else { continue }

            removed.removeAll { $0 == key }
        }

        return removed
    }

    private func Flush()
    {
        guard let executor else { return }

        let commands = buffer
        buffer.removeAll()
        commands.forEach { executor.Execute( $0 ) }
    }
}
