//
//  MapNavigationController.swift
//  HudHud
//
//  Created by Naif Alrashed on 21/07/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import MapboxNavigation
import UIKit

final class MapNavigationViewController: NavigationViewController {

    var onViewSafeAreaInsetsDidChange: ((UIEdgeInsets) -> Void)?

    // MARK: - Internal

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        self.onViewSafeAreaInsetsDidChange?(view.safeAreaInsets)
    }
}
