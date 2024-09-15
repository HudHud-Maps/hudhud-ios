//
//  MapNavigationViewController.swift
//  HudHud
//
//  Created by Naif Alrashed on 15/09/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import MapboxNavigation
import UIKit

class MapNavigationViewController: NavigationViewController {

    // MARK: Properties

    var onViewSafeAreaInsetsDidChange: ((UIEdgeInsets) -> Void)?

    // MARK: Overridden Functions

    // MARK: - Internal

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        self.onViewSafeAreaInsetsDidChange?(view.safeAreaInsets)
    }
}
