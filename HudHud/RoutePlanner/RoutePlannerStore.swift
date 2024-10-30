//
//  RoutePlannerStore.swift
//  HudHud
//
//  Created by Naif Alrashed on 30/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

// MARK: - RoutePlannerStore

@Observable
@MainActor
final class RoutePlannerStore {}

// MARK: - Previewable

extension RoutePlannerStore: Previewable {
    static let storeSetUpForPreviewing = RoutePlannerStore()
}
