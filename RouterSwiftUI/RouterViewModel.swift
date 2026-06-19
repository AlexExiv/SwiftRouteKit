import Combine
import Foundation

@MainActor
open class RouterViewModel: ObservableObject
{
    public private(set) weak var router: (any Router)?
    public private(set) var resultProvider: ResultProvider?

    private var isInitialized = false

    public init()
    {
    }

    final func Prepare( router: any Router, resultProvider: ResultProvider )
    {
        self.router = router
        self.resultProvider = resultProvider

        guard isInitialized == false else { return }

        isInitialized = true
        OnRouterBound()
    }

    open func OnRouterBound()
    {
    }
}
