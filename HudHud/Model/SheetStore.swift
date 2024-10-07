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

    // MARK: - Private Properties

    private var _sheets: [SheetViewData] = []
    private var defaultAllowedDetents: Set<PresentationDetent> = [.small, .third, .large]
    private let defaultSelectedDetent: PresentationDetent = .third
    private var newSheetSelectedDetent: PresentationDetent?

    private let updateActor = UpdateActor()

    // MARK: Computed Properties

    // MARK: - Public Properties

    var currentSheet: SheetViewData? { self._sheets.last }

    var sheets: [SheetViewData] {
        get { self._sheets }
        set { self.updateSheets(newValue) }
    }

    var selectedDetent: PresentationDetent {
        get { self.newSheetSelectedDetent ?? self.currentSheet?.selectedDetent ?? self.defaultSelectedDetent }
        set { self.updateSelectedDetent(newValue) }
    }

    var allowedDetents: Set<PresentationDetent> {
        get {
            var detents = self.currentSheet?.allowedDetents ?? self.defaultAllowedDetents
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
        self.updateSheets(self._sheets + [sheet])
    }

    func popSheet() {
        guard !self._sheets.isEmpty else { return }
        self.updateSheets(Array(self._sheets.dropLast()))
    }

    func reset() {
        self.updateSheets([])
    }

    // MARK: - Private Methods

    private func updateSheets(_ newSheets: [SheetViewData]) {
        Task {
            await self.updateActor.update {
                guard self._sheets.count != newSheets.count else {
                    self._sheets = newSheets
                    return
                }

                self.newSheetSelectedDetent = newSheets.last?.selectedDetent ?? self.defaultSelectedDetent
                try? await Task.sleep(nanoseconds: 100 * NSEC_PER_MSEC)
                withAnimation {
                    self._sheets = newSheets
                    self.newSheetSelectedDetent = nil
                }
            }
        }
    }

    private func updateSelectedDetent(_ newValue: PresentationDetent) {
        Task {
            await self.updateActor.update {
                if self._sheets.isEmpty {
                    self.newSheetSelectedDetent = newValue
                    return
                }

                if let lastIndex = self._sheets.indices.last {
                    self._sheets[lastIndex].selectedDetent = newValue
                }
            }
        }
    }

    private func updateAllowedDetents(_ newValue: Set<PresentationDetent>) {
        Task {
            await self.updateActor.update {
                if self._sheets.isEmpty {
                    self.defaultAllowedDetents = newValue
                } else {
                    if let lastIndex = self._sheets.indices.last {
                        self._sheets[lastIndex].allowedDetents = newValue
                    }
                }
            }
        }
    }
}

// MARK: - UpdateActor

actor UpdateActor {
    func update(_ operation: @escaping () async -> Void) async {
        await operation()
    }
}

// MARK: - SheetStore + Previewable

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

    var selectedDetent: PresentationDetent
    var allowedDetents: Set<PresentationDetent>

    // MARK: Lifecycle

    init(viewData: ViewData) {
        self.viewData = viewData
        self.selectedDetent = viewData.initialSelectedDetent
        self.allowedDetents = viewData.initialAllowedDetents
    }
}
