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
import SwiftUI

// MARK: - SheetStore

/// this handles sheet states related to
/// * the navigation path
/// * the selected detent
/// * the allowed detent
@MainActor
@Observable
final class SheetStore {

    // MARK: Properties

    var newSheetSelectedDetent: PresentationDetent?
    var previousSheetSelectedDetent: PresentationDetent?

    private(set) var emptySheetSelectedDetent: PresentationDetent = .third

    private var _sheets: [SheetViewData] = []
    private var emptySheetAllowedDetents: Set<PresentationDetent> = [.small, .third, .large]

    // MARK: Computed Properties

    var sheets: [SheetViewData] {
        get {
            self._sheets
        }

        set {
            Task {
                await self.setNewSheetsInAnAnimationFriendlyWay(newSheets: newValue)
            }
        }
    }

    var selectedDetent: PresentationDetent {
        get {
            self.newSheetSelectedDetent ?? self._sheets.last?.selectedDetent ?? self.emptySheetSelectedDetent
        }

        set {
            if let lastIndex = self.sheets.indices.last {
                self._sheets[lastIndex].selectedDetent = newValue
            } else {
                self.emptySheetSelectedDetent = newValue
            }
        }
    }

    var allowedDetents: Set<PresentationDetent> {
        get {
            var allowedDetents = if self._sheets.isEmpty {
                self.emptySheetAllowedDetents
            } else {
                self._sheets[self._sheets.count - 1].allowedDetents
            }
            if let previousSheetSelectedDetent {
                allowedDetents.insert(previousSheetSelectedDetent)
            }
            if let newSheetSelectedDetent {
                allowedDetents.insert(newSheetSelectedDetent)
            }
            return allowedDetents
        }

        set {
            if self._sheets.isEmpty {
                self.emptySheetAllowedDetents = newValue
            } else {
                self._sheets[self._sheets.count - 1].allowedDetents = newValue
            }
        }
    }

    var transition: AnyNavigationTransition {
        self._sheets.last?.viewData.transition ?? .fade(.cross)
    }

    // MARK: Functions

    func reset() {
        self._sheets = []
    }

    // we do this to fix UI transition glitches
    // the way the fix happens is by adding the new sheet's selected detent to
    // the current selected & allowed detents, then wait for 100 ms
    // the current selected & allowed detents, then wait for a little bit
    // then apply the sheet transition
    private func setNewSheetsInAnAnimationFriendlyWay(newSheets: [SheetViewData]) async {
        guard self._sheets.count != newSheets.count else {
            self._sheets = newSheets
            return
        }
        self.newSheetSelectedDetent = newSheets.last?.selectedDetent ?? self.emptySheetSelectedDetent
        try? await Task.sleep(nanoseconds: 100 * NSEC_PER_MSEC)
        self._sheets = newSheets
        self.newSheetSelectedDetent = nil
    }

    // needed to fix animation jumping sheet when transitioning
    private func temporarilyAddLastSelectedDetent(previousSheets: [SheetViewData]) async {
        guard self._sheets.count != previousSheets.count else {
            return
        }

        self.previousSheetSelectedDetent = previousSheets.last?.selectedDetent ?? self.emptySheetSelectedDetent
        try? await Task.sleep(nanoseconds: 250 * NSEC_PER_MSEC)
        self.previousSheetSelectedDetent = nil
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
                [.height(340), .large]
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

    private var cachedSelectedDetent: PresentationDetent?
    private var cachedAllowedDetents: Set<PresentationDetent>?

    // MARK: Computed Properties

    var selectedDetent: PresentationDetent {
        get {
            self.cachedSelectedDetent ?? self.viewData.initialSelectedDetent
        }

        set {
            self.cachedSelectedDetent = newValue
        }
    }

    var allowedDetents: Set<PresentationDetent> {
        get {
            self.cachedAllowedDetents ?? self.viewData.initialAllowedDetents
        }

        set {
            self.cachedAllowedDetents = newValue
        }
    }

    // MARK: Lifecycle

    init(viewData: ViewData) {
        self.viewData = viewData
    }
}
