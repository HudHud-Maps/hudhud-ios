import SwiftUI
import UIKit

public enum NavigationMapViewContentInsetMode {

    case landscape(within: GeometryProxy, verticalPct: CGFloat = 0.75, horizontalPct: CGFloat = 0.5)

    case portrait(within: GeometryProxy, verticalPct: CGFloat = 0.75, minHeight: CGFloat = 210)

    case edgeInset(UIEdgeInsets)

    // MARK: Computed Properties

    var uiEdgeInsets: UIEdgeInsets {
        switch self {
        case let .landscape(geometry, verticalPct, horizontalPct):
            let top = geometry.size.height * verticalPct
            let leading = geometry.size.width * horizontalPct

            return UIEdgeInsets(top: top, left: leading, bottom: 0, right: 0)
        case let .portrait(geometry, verticalPct, minVertical):
            let ideal = geometry.size.height * verticalPct
            let max = geometry.size.height - minVertical
            let top = min(max, ideal)

            return UIEdgeInsets(top: top, left: 0, bottom: 0, right: 0)
        case let .edgeInset(uIEdgeInsets):
            return uIEdgeInsets
        }
    }

    // MARK: Lifecycle

    public init(orientation: UIDeviceOrientation, geometry: GeometryProxy) {
        switch orientation {
        case .landscapeLeft, .landscapeRight:
            self = .landscape(within: geometry)
        default:
            self = .portrait(within: geometry)
        }
    }

}
