//
//  NavigationPath.swift
//  HudHud
//
//  Created by patrick on 28.05.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import OSLog
import POIService
import SwiftUI

// MARK: - NavPath

struct NavPath {
    var elements: [Any] = []
}

// MARK: - Decodable

extension NavPath: Decodable {
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.elements = []

        while !container.isAtEnd {
            let typeName = try container.decode(String.self)
            var type = _typeByName(typeName) as? any Decodable.Type
            if type == nil, typeName == "POIService.ResolvedItem" {
                // _typeByName doesn't work for things in other packages yet
                type = POIService.ResolvedItem.self
            }
            if type == nil, typeName == "POIService.Toursprung.RouteCalculationResult" {
                // _typeByName doesn't work for things in other packages yet
                type = POIService.Toursprung.RouteCalculationResult.self
            }
            if type == nil, typeName == "HudHud.SheetSubView" {
                // _typeByName doesn't work for things in other packages yet
                type = SheetSubView.self
            }
            guard let type else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "\(typeName) is not decodable."
                )
            }

            let encodedValue = try container.decode(String.self)
            let value = try JSONDecoder().decode(type, from: Data(encodedValue.utf8))
            self.elements.insert(value, at: 0)
        }
    }
}

extension NavigationPath {

    enum CustomNavigationPathError: Error {
        case codableIsNil
    }

    func elements() throws -> [Any] {
        // NavigationPath offers no way to see whats currently in it, so we workaround this with its JSON encoding system
        guard let codable = self.codable else {
            throw CustomNavigationPathError.codableIsNil
        }
        let encodedData = try JSONEncoder().encode(codable)
        let decodedPath = try JSONDecoder().decode(NavPath.self, from: encodedData)
        return decodedPath.elements
    }

    func contains<T>(_: T.Type) -> Bool {
        do {
            let elements = try self.elements()
            return elements.contains(where: { something in
                return something is T
            })
        } catch {
            Logger.sheet.error("Current NavigationPath cannot be decoded: \(error)")
            return false
        }
    }
}
