//
//  NavigationViewCoordinator.swift
//  HudHud
//
//  Created by Patrick Kladek on 01.03.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import MapboxNavigation
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI

// MARK: - NavigationViewCoordinator

public class NavigationViewCoordinator: NSObject {

	// This must be weak, the UIViewRepresentable owns the MLNMapView.
	weak var mapView: NavigationMapView?
	var parent: NavigationView

	// MARK: - Lifecycle

	init(parent: NavigationView) {
		self.parent = parent
	}
}

// MARK: - MLNMapViewDelegate

extension NavigationViewCoordinator: NavigationMapViewDelegate {}
