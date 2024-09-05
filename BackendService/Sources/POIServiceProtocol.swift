//
//  POIServiceProtocol.swift
//  BackendService
//
//  Created by Patrick Kladek on 05.09.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation
import SFSafeSymbols

// MARK: - POIServiceProtocol

public protocol POIServiceProtocol {

    static var serviceName: String { get }
    func lookup(id: String, prediction: Any, baseURL: String) async throws -> [ResolvedItem]
    func predict(term: String, coordinates: CLLocationCoordinate2D?, baseURL: String) async throws -> POIResponse
}
