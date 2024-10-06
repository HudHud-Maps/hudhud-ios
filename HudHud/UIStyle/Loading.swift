//
//  Loading.swift
//  HudHud
//
//  Created by Fatima Aljaber on 29/09/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

struct Loading {

    // MARK: Nested Types

    enum LoadingState {
        case idle
        case initialLoading
        case loading
        case result
    }

    // MARK: Properties

    public var state: LoadingState = .idle
    public var resultIsEmpty: Bool = false

    // MARK: Computed Properties

    var shouldShowNoResult: Bool {
        switch self.state {
        case .idle, .initialLoading, .loading:
            false
        case .result:
            self.resultIsEmpty
        }
    }

    var shouldShowLoadingCircle: Bool {
        switch self.state {
        case .idle, .initialLoading, .result:
            false
        case .loading:
            true
        }
    }
}
