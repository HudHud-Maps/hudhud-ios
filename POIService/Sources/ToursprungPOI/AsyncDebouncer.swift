//
//  AsyncDebouncer.swift
//  ToursprungPOI
//
//  Created by Patrick Kladek on 22.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

public actor AsyncDebouncer<Input, Output> {

	enum DebouncerError: Error {
		case taskCanceled
	}

	private var task: Task<Output, Error>?
	private let delay: TimeInterval

	// MARK: - Lifecycle

	public init(delay: TimeInterval = 0.2) {
		self.delay = delay
	}

	// MARK: - AsyncDebouncer

	public func debounce(input: Input, action: @escaping (Input) async throws -> Output) async throws -> Output {
		self.task?.cancel()

		let localTask = Task {
			try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

			guard !Task.isCancelled else {
				throw DebouncerError.taskCanceled
			}

			return try await action(input)
		}
		self.task = localTask
		return try await localTask.value
	}
}
