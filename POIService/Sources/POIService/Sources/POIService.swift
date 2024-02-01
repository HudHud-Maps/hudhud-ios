//
//  POIService.swift
//  POIService
//
//  Created by Patrick Kladek on 01.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import CoreLocation

public protocol POIServiceProtocol {

    static var serviceName: String { get }

    func search(term: String) async throws -> [POI]
}

public struct POI {

    public var name: String
    public var locationCoordinate: CLLocationCoordinate2D
    public var type: String

    public init(name: String, locationCoordinate: CLLocationCoordinate2D, type: String) {
        self.name = name
        self.locationCoordinate = locationCoordinate
        self.type = type
    }
}
