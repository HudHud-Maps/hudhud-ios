//
//  ObservedChild.swift
//  HudHud
//
//  Created by Ali Hilal on 26/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Combine
import Foundation
import Observation

@propertyWrapper
struct ObservedChild<T: ObservableObject> {

    // MARK: Properties

    var wrappedValue: T

    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    // MARK: Lifecycle

    init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }

    // MARK: Static Functions

    static subscript<EnclosingSelf: ObservableObject>(
        _enclosingInstance instance: EnclosingSelf,
        wrapped _: ReferenceWritableKeyPath<EnclosingSelf, T>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
    ) -> T {
        get {
            var wrapper = instance[keyPath: storageKeyPath]

            if wrapper.cancellables.isEmpty {
                wrapper.wrappedValue.objectWillChange
                    .sink { _ in
                        (instance.objectWillChange as? ObservableObjectPublisher)?.send()
                    }
                    .store(in: &wrapper.cancellables)
            }

            return wrapper.wrappedValue
        }
        set {
            instance[keyPath: storageKeyPath].wrappedValue = newValue
        }
    }

    static subscript<EnclosingSelf: Observable>(
        _enclosingObservableInstance instance: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, T>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
    ) -> T {
        get {
            var wrapper = instance[keyPath: storageKeyPath]

            if wrapper.cancellables.isEmpty {
                wrapper.wrappedValue.objectWillChange
                    .sink { _ in
                        if let mirror = Mirror(reflecting: instance).children.first(where: { $0.label == "_$observationRegistrar" }),
                           let registrar = mirror.value as? ObservationRegistrar {
                            registrar.withMutation(of: instance, keyPath: wrappedKeyPath) {}
                        }
                    }
                    .store(in: &wrapper.cancellables)
            }

            return wrapper.wrappedValue
        }
        set {
            instance[keyPath: storageKeyPath].wrappedValue = newValue
        }
    }
}
