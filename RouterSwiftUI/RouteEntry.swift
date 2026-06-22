import Foundation
import SwiftUI

@MainActor
public final class RouteEntry: Identifiable, Hashable
{
    public nonisolated let id: String
    public let path: AnyRoutePath
    public let controller: any AnyRouteController
    public let presentationStyle: RoutePresentationStyle
    public let containerStyle: RouteContainerStyle
    public let resultProvider: ResultProvider
    public private( set ) weak var router: ( any Router )?

    public var viewModel: RouterViewModel?
    public var lockBack = false

    init( id: String = UUID().uuidString, path: AnyRoutePath, controller: any AnyRouteController, presentationStyle: RoutePresentationStyle, containerStyle: RouteContainerStyle, router: ( any Router )?, resultBinding: RouteResultBinding? )
    {
        self.id = id
        self.path = path
        self.controller = controller
        self.presentationStyle = presentationStyle
        self.containerStyle = containerStyle
        self.router = router
        self.resultProvider = ResultProvider( key: id, resultBinding: resultBinding )
    }

    public nonisolated static func == ( lhs: RouteEntry, rhs: RouteEntry ) -> Bool
    {
        lhs.id == rhs.id
    }

    public nonisolated func hash( into hasher: inout Hasher )
    {
        hasher.combine( id )
    }
}

public extension RouteEntry
{
    var isPush: Bool
    {
        if case .push = presentationStyle
        {
            return true
        }

        return false
    }
}
