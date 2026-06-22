import Combine
import SwiftUI

@MainActor
public final class SwiftUINavigator: ObservableObject
{
    public var root: RouteEntry?
    {
        fullItems.first
    }

    public var stack: [RouteEntry]
    {
        get
        {
            Array( fullItems.dropFirst() )
        }
        set
        {
            let visibleFullEntries = ([root].compactMap { $0 } + newValue)
            let visibleFullIDs = Set( visibleFullEntries.map( \.id ) )
            var ownerIsVisible = false

            items = items.filter {
                if case .push = $0.presentationStyle
                {
                    ownerIsVisible = visibleFullIDs.contains( $0.id )
                    return ownerIsVisible
                }

                return ownerIsVisible
            }
        }
    }

    public var sheet: RouteEntry?
    {
        get
        {
            guard case .dialog = items.last?.presentationStyle else { return nil }
            return items.last
        }
        set
        {
            if newValue == nil, let sheet
            {
                Remove( entry: sheet )
            }
        }
    }

    public var bottomSheet: RouteEntry?
    {
        get
        {
            guard case .bottomSheet = items.last?.presentationStyle else { return nil }

            return items.last
        }
        set
        {
            if newValue == nil, let bottomSheet
            {
                Remove( entry: bottomSheet )
            }
        }
    }

    public var fullScreen: RouteEntry?
    {
        get
        {
            guard case .fullScreen = items.last?.presentationStyle else { return nil }

            return items.last
        }
        set
        {
            if newValue == nil, let fullScreen
            {
                Remove( entry: fullScreen )
            }
        }
    }

    public var visibleEntryIDs: [String]
    {
        items.map( \.id )
    }

    var isNoNavigationStack: Bool
    {
        root?.containerStyle == .tabs && stack.isEmpty
    }

    public var stackBinding: Binding<[RouteEntry]>
    {
        Binding(
            get: { self.stack },
            set: { self.stack = $0 } )
    }

    public var sheetBinding: Binding<RouteEntry?>
    {
        Binding(
            get: { self.sheet },
            set: { self.sheet = $0 } )
    }

    public var bottomSheetBinding: Binding<RouteEntry?>
    {
        Binding(
            get: { self.bottomSheet },
            set: { self.bottomSheet = $0 } )
    }

    public var fullScreenBinding: Binding<RouteEntry?>
    {
        Binding(
            get: { self.fullScreen },
            set: { self.fullScreen = $0 } )
    }

    @Published
    public private(set) var items = [RouteEntry]()

    private var fullItems: [RouteEntry]
    {
        items.filter {
            if case .push = $0.presentationStyle
            {
                return true
            }

            return false
        }
    }

    public init()
    {
    }

    func SetRoot( _ entry: RouteEntry )
    {
        items = [entry]
    }

    func Push( _ entry: RouteEntry )
    {
        items.append( entry )
    }

    func Replace( entry: RouteEntry, replacing key: String? )
    {
        guard let key else
        {
            SetRoot( entry )
            return
        }

        guard let index = items.firstIndex( where: { $0.id == key } ) else
        {
            Push( entry )
            return
        }

        items[index] = entry
    }

    func Remove( entry: RouteEntry? )
    {
        guard let entry else
        {
            _ = items.popLast()
            return
        }

        items.removeAll { $0.id == entry.id }
    }

    func RemoveTo( key: String )
    {
        guard let index = items.firstIndex( where: { $0.id == key } ) else
        {
            items.removeAll()
            return
        }

        items.removeLast( items.count - index - 1 )
    }

    func RemoveAll()
    {
        items.removeAll()
    }

}

@MainActor
public final class SwiftUICommandExecutor: CommandExecutor
{
    private weak var navigator: SwiftUINavigator?

    public init( navigator: SwiftUINavigator )
    {
        self.navigator = navigator
    }

    public func Execute( _ command: RouterCommand )
    {
        guard let navigator else { return }

        switch command
        {
        case .setRoot( let entry ):
            navigator.SetRoot( entry )
        case .push( let entry ):
            navigator.Push( entry )
        case .replace( let entry, let replacing ):
            navigator.Replace( entry: entry, replacing: replacing )
        case .presentDialog( let entry ):
            navigator.Push( entry )
        case .presentBottomSheet( let entry ):
            navigator.Push( entry )
        case .presentFullScreen( let entry ):
            navigator.Push( entry )
        case .close( let entry ):
            navigator.Remove( entry: entry )
        case .closeTo( let key ):
            navigator.RemoveTo( key: key )
        case .closeAll:
            navigator.RemoveAll()
        case .selectTab:
            break
        }
    }

    public func Sync( entries: [String] ) -> [String]
    {
        guard let navigator else { return [] }

        let visible = Set( navigator.visibleEntryIDs )
        return entries.filter { visible.contains( $0 ) == false }
    }
}
