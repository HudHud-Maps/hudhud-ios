//
//  AnyDisplayableAsRow.swift
//  BackendService
//
//  Created by Patrick Kladek on 05.09.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SFSafeSymbols

// MARK: - AnyDisplayableAsRow

public struct AnyDisplayableAsRow: DisplayableAsRow {

    // MARK: Properties

    public var innerModel: any DisplayableAsRow

    // MARK: Computed Properties

    public var title: String {
        self.innerModel.title
    }

    public var subtitle: String {
        self.innerModel.subtitle
    }

    public var symbol: SFSymbol {
        self.innerModel.symbol
    }

    public var id: String { self.innerModel.id }

    // MARK: Lifecycle

    public init(_ model: some DisplayableAsRow) {
        self.innerModel = model // Automatically casts to “any” type
    }

    // MARK: Static Functions

    // MARK: - Public

    public static func == (lhs: AnyDisplayableAsRow, rhs: AnyDisplayableAsRow) -> Bool {
        return lhs.id == rhs.id
    }

    // MARK: Functions

    public func resolve(in provider: ApplePOI, baseURL: String) async throws -> [AnyDisplayableAsRow] {
        return try await self.innerModel.resolve(in: provider, baseURL: baseURL)
    }

    public func resolve(in provider: HudHudPOI, baseURL: String) async throws -> [AnyDisplayableAsRow] {
        return try await self.innerModel.resolve(in: provider, baseURL: baseURL)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.title)
        hasher.combine(self.subtitle)
        hasher.combine(self.symbol)
        hasher.combine(self.id)
    }
}
