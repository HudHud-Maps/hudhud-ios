//
//  CLLocationCoordinate2D.swift
//  HudHud
//
//  Created by Patrick Kladek on 02.04.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation

extension CLLocationCoordinate2D {

	static let zero = CLLocationCoordinate2D(latitude: 0, longitude: 0)
	static let riyadh = CLLocationCoordinate2D(latitude: 24.65333, longitude: 46.71526)
	static let jeddah = CLLocationCoordinate2D(latitude: 21.54238, longitude: 39.19797)

	// Used for testing StreetView
	static let image1 = CLLocationCoordinate2D(latitude: 21.54238, longitude: 39.19797)
	static let image2 = CLLocationCoordinate2D(latitude: 25, longitude: 46)
	static let image3 = CLLocationCoordinate2D(latitude: 20, longitude: 40)
}
