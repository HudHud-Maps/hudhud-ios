//
//  DictionaryConvertable.swift
//  BackendService
//
//  Created by Patrick Kladek on 12.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

// MARK: - DictionaryConvertable

public protocol DictionaryConvertable: CustomStringConvertible {
    func dictionary() -> [String: AnyHashable]
}

public extension DictionaryConvertable {

    func dictionary() -> [String: AnyHashable] {
        var dict = [String: AnyHashable]()
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            guard let key = child.label else { continue }

            let childMirror = Mirror(reflecting: child.value)
            switch childMirror.displayStyle {
            case .struct, .class:
                if let childDict = (child.value as? DictionaryConvertable)?.dictionary() {
                    dict[key] = childDict
                }
            case .collection:
                if let childArray = (child.value as? [DictionaryConvertable])?.compactMap({ $0.dictionary() }) {
                    dict[key] = childArray
                }
            case .set:
                if let childArray = (child.value as? Set<AnyHashable>)?.compactMap({ ($0 as? DictionaryConvertable)?.dictionary() }) {
                    dict[key] = childArray
                }
            default:
                if let child = child.value as? CustomStringConvertible {
                    dict[key] = child.description
                }

                dict[key] = child.value as? AnyHashable
            }
        }

        return dict
    }
}
