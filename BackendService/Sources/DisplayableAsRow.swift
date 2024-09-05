//
//  DisplayableAsRow.swift
//  BackendService
//
//  Created by Patrick Kladek on 05.09.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SFSafeSymbols

// MARK: - DisplayableAsRow

public protocol DisplayableAsRow: Identifiable, Hashable {
    var id: String { get }
    var title: String { get }
    var subtitle: String { get }
    var symbol: SFSymbol { get }

    func resolve(in provider: ApplePOI, baseURL: String) async throws -> [AnyDisplayableAsRow]
    func resolve(in provider: HudHudPOI, baseURL: String) async throws -> [AnyDisplayableAsRow]
}

public extension DisplayableRow {

    static let ketchup: DisplayableRow = .resolvedItem(ResolvedItem.ketchup)
    static let starbucks: DisplayableRow = .resolvedItem(ResolvedItem.starbucks)
    static let publicPlace: DisplayableRow = .resolvedItem(ResolvedItem.publicPlace)
    static let artwork: DisplayableRow = .resolvedItem(ResolvedItem.artwork)
    static let pharmacy: DisplayableRow = .resolvedItem(ResolvedItem.pharmacy)
    static let supermarket: DisplayableRow = .resolvedItem(ResolvedItem.supermarket)
}
