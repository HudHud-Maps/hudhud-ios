//
//  ObservedMacroChild.swift
//  HudHud
//
//  Created by Ali Hilal on 26/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

// Experimental
@propertyWrapper
struct ObservedMacroChild<T: Observable> {

    // MARK: Properties

    var wrappedValue: T

    // MARK: Lifecycle

    init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }

    // MARK: Static Functions

    static subscript<EnclosingSelf: Observable>(
        _enclosingInstance instance: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, T>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
    ) -> T {
        get {
            var wrapper = instance[keyPath: storageKeyPath]
            if let mirror = Mirror(reflecting: instance).children.first(where: { $0.label == "_$observationRegistrar" }),
               let registrar = mirror.value as? ObservationRegistrar {
                registrar.withMutation(of: instance, keyPath: wrappedKeyPath) {}
            }

            return wrapper.wrappedValue
        }
        set {
            instance[keyPath: storageKeyPath].wrappedValue = newValue
        }
    }
}
