//
//  NestedObservableObject.swift
//  HudHud
//
//  Created by Patrick Kladek on 02.04.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Combine
import Foundation

//
// @ref https://www.swiftbysundell.com/articles/accessing-a-swift-property-wrappers-enclosing-instance/
// @ref https://stackoverflow.com/a/58406402/521197
// @ref https://gist.github.com/bsorrentino/3bd923b85ce0e8421b59c87f8f470874
//

@propertyWrapper
struct NestedObservableObject<Value: ObservableObject> {

	@available(*, unavailable, message: "This property wrapper can only be applied to classes")
	var wrappedValue: Value {
		get { fatalError() } // swiftlint:disable:this disable_fatalError
		set { fatalError() } // swiftlint:disable:this disable_fatalError unused_setter_value
	}

	private var cancellable: AnyCancellable?
	private var storage: Value

	// MARK: - Lifecycle

	init(wrappedValue: Value) {
		self.storage = wrappedValue
	}

	// MARK: - Internal

	static subscript<T: ObservableObject>(
		_enclosingInstance instance: T,
		wrapped _: ReferenceWritableKeyPath<T, Value>,
		storage storageKeyPath: ReferenceWritableKeyPath<T, Self>
	) -> Value {
		get {
			if instance[keyPath: storageKeyPath].cancellable == nil, let publisher = instance.objectWillChange as? ObservableObjectPublisher {
				instance[keyPath: storageKeyPath].cancellable =
					instance[keyPath: storageKeyPath].storage.objectWillChange.sink { _ in
						publisher.send()
					}
			}

			return instance[keyPath: storageKeyPath].storage
		}
		set {
			if let cancellable = instance[keyPath: storageKeyPath].cancellable {
				cancellable.cancel()
			}
			if let publisher = instance.objectWillChange as? ObservableObjectPublisher {
				instance[keyPath: storageKeyPath].cancellable =
					newValue.objectWillChange.sink { _ in
						publisher.send()
					}
			}
			instance[keyPath: storageKeyPath].storage = newValue
		}
	}
}
