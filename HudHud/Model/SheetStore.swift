//
//  SheetStore.swift
//  HudHud
//
//  Created by Naif Alrashed on 03/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import Foundation
import NavigationTransition
import Semaphore
import SwiftUI

// MARK: - SheetStore

/// this handles sheet states related to
/// * the navigation path
/// * the selected detent
/// * the allowed detent
/// * the sheet's visibility
@MainActor
@Observable
final class SheetStore {

    // MARK: Properties

    // MARK: - Public Properties

    var isShown: Bool = true

    private(set) var emptySheetAllowedDetents: Set<PresentationDetent> = [.small, .third, .large]
    private(set) var emptySheetSelectedDetent: PresentationDetent = .third
    private(set) var uiKitEmptySheetAllowedDetents: [Detent] = [.small, .third, .large]
    private(set) var uiKitEmptySheetSelectedDetent: Detent = .third

    // MARK: - Private Properties

    private var _sheets: [SheetViewData] = []
    private var newSheetSelectedDetent: PresentationDetent?

    private let semaphore = AsyncSemaphore(value: 1)

    private let defaultAllowedDetents: Set<PresentationDetent> = [.small, .third, .large]
    private let defaultSelectedDetent: PresentationDetent = .third

    // MARK: Computed Properties

    var currentSheet: SheetViewData? { self._sheets.last }

    var sheets: [SheetViewData] {
        get { self._sheets }
        set { Task { await self.updateSheets(newValue) } }
    }

    var selectedDetent: PresentationDetent {
        get {
            self.newSheetSelectedDetent ?? self.currentSheet?.selectedDetent ?? self.emptySheetSelectedDetent
        }
        set { self.updateSelectedDetent(newValue) }
    }

    var allowedDetents: Set<PresentationDetent> {
        get {
            var detents = self.currentSheet?.allowedDetents ?? self.emptySheetAllowedDetents
            if let newSheetSelectedDetent {
                detents.insert(newSheetSelectedDetent)
            }
            return detents
        }
        set { self.updateAllowedDetents(newValue) }
    }

    var transition: AnyNavigationTransition {
        self.currentSheet?.viewData.transition ?? .fade(.cross)
    }

    // MARK: Functions

    // MARK: - Public Methods

    func pushSheet(_ sheet: SheetViewData) {
        self.sheets.append(sheet)
    }

    @discardableResult
    func popSheet() -> SheetViewData? {
        self.sheets.popLast()
    }

    func reset() {
        self.emptySheetAllowedDetents = self.defaultAllowedDetents
        self.emptySheetSelectedDetent = self.defaultSelectedDetent
        self.sheets.removeAll()
    }

    // MARK: - Private Methods

    private func updateSheets(_ newSheets: [SheetViewData]) async {
        await self.semaphore.wait()
        defer { semaphore.signal() }
        guard self._sheets.count != newSheets.count else {
            self._sheets = newSheets
            return
        }
        self.newSheetSelectedDetent = newSheets.last?.selectedDetent ?? self.emptySheetSelectedDetent
        try? await Task.sleep(nanoseconds: 100 * NSEC_PER_MSEC)
        self._sheets = newSheets
        self.newSheetSelectedDetent = nil
    }

    private func updateSelectedDetent(_ newValue: PresentationDetent) {
        if let lastIndex = self._sheets.indices.last {
            self._sheets[lastIndex].selectedDetent = newValue
        } else {
            self.emptySheetSelectedDetent = newValue
        }
    }

    private func updateAllowedDetents(_ newValue: Set<PresentationDetent>) {
        if let lastIndex = self._sheets.indices.last {
            self._sheets[lastIndex].allowedDetents = newValue
        } else {
            self.emptySheetAllowedDetents = newValue
        }
    }
}

// MARK: - Previewable

extension SheetStore: Previewable {
    static let storeSetUpForPreviewing = SheetStore()
}

// MARK: - SheetViewData

struct SheetViewData: Hashable {

    // MARK: Nested Types

    enum ViewData: Hashable {
        case mapStyle
        case debugView
        case navigationAddSearchView
        case favorites
        case navigationPreview
        case pointOfInterest(ResolvedItem)
        case favoritesViewMore
        case editFavoritesForm(item: ResolvedItem, favoriteItem: FavoritesItem? = nil)

        // MARK: Computed Properties

        /// the allowed detents when the page is first presented, it can be changed later
        var initialAllowedDetents: Set<PresentationDetent> {
            switch self {
            case .mapStyle:
                [.medium]
            case .debugView:
                [.large]
            case .navigationAddSearchView:
                [.large]
            case .favorites:
                [.large]
            case .navigationPreview:
                [.height(150), .nearHalf]
            case .pointOfInterest:
                [.height(340)]
            case .favoritesViewMore:
                [.large]
            case .editFavoritesForm:
                [.large]
            }
        }

        /// the allowed detents when the page is first presented, it can be changed later
        var uiKitInitialAllowedDetents: [Detent] {
            switch self {
            case .mapStyle:
                [.medium]
            case .debugView:
                [.large]
            case .navigationAddSearchView:
                [.large]
            case .favorites:
                [.large]
            case .navigationPreview:
                [.height(150), .fraction(0.5)]
            case .pointOfInterest:
                [.height(340)]
            case .favoritesViewMore:
                [.large]
            case .editFavoritesForm:
                [.large]
            }
        }

        /// the selected detent when the page is first presented, it can be changed later
        var initialSelectedDetent: PresentationDetent {
            switch self {
            case .mapStyle:
                .medium
            case .debugView:
                .large
            case .navigationAddSearchView:
                .large
            case .favorites:
                .large
            case .navigationPreview:
                .nearHalf
            case .pointOfInterest:
                .height(340)
            case .favoritesViewMore:
                .large
            case .editFavoritesForm:
                .large
            }
        }

        /// the selected detent when the page is first presented, it can be changed later
        var uiKitInitialSelectedDetent: Detent {
            switch self {
            case .mapStyle:
                .medium
            case .debugView:
                .large
            case .navigationAddSearchView:
                .large
            case .favorites:
                .large
            case .navigationPreview:
                .fraction(0.5)
            case .pointOfInterest:
                .height(340)
            case .favoritesViewMore:
                .large
            case .editFavoritesForm:
                .large
            }
        }

        var transition: AnyNavigationTransition {
            switch self {
            case .editFavoritesForm:
                .default
            default:
                .fade(.cross)
            }
        }
    }

    // MARK: Properties

    let viewData: ViewData

    var selectedDetent: PresentationDetent
    var allowedDetents: Set<PresentationDetent>

    var uiKitSelectedDetent: Detent
    var uiKitAllowedDetents: [Detent]

    // MARK: Lifecycle

    init(viewData: ViewData) {
        self.viewData = viewData
        self.selectedDetent = viewData.initialSelectedDetent
        self.allowedDetents = viewData.initialAllowedDetents
        self.uiKitAllowedDetents = viewData.uiKitInitialAllowedDetents
        self.uiKitSelectedDetent = viewData.uiKitInitialSelectedDetent
    }
}
