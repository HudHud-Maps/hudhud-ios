//
//  SheetStore.swift
//  HudHud
//
//  Created by Naif Alrashed on 03/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import Combine
import Foundation
import SwiftUI

// MARK: - SheetStore

/// this handles sheet states related to
/// * the navigation path
/// * the selected detent
/// * the allowed detent
/// * the sheet's visibility

@Observable
@MainActor
final class SheetStore {

    // MARK: Properties

    let navigationCommands = PassthroughSubject<NavigationCommand, Never>()
    var isShown = CurrentValueSubject<Bool, Never>(true)

    private var sheets: [SheetData] = []

    private let emptySheetData: SheetData

    // MARK: Computed Properties

    var currentSheet: SheetData {
        self.sheets.last ?? self.emptySheetData
    }

    var selectedDetent: Detent {
        get {
            self.currentSheet.detentData.value.selectedDetent
        }
        set {
            self.currentSheet.detentData.value.selectedDetent = newValue
        }
    }

    // MARK: Lifecycle

    init(emptySheetType: SheetType) {
        self.emptySheetData = SheetData(
            sheetType: emptySheetType,
            detentData: CurrentValueSubject<DetentData, Never>(emptySheetType.initialDetentData)
        )
    }

    // MARK: Functions

    func start() {
        self.navigationCommands.send(.show(self.emptySheetData))
    }

    func show(_ sheetType: SheetType) {
        let detentCurrentValueSubject = CurrentValueSubject<DetentData, Never>(sheetType.initialDetentData)
        let sheetData = SheetData(sheetType: sheetType, detentData: detentCurrentValueSubject)
        self.sheets.append(sheetData)
        self.navigationCommands.send(.show(sheetData))
    }

    func popSheet() {
        guard !self.sheets.isEmpty else {
            return
        }
        _ = self.sheets.popLast()
        let destinationDetentCurrentValueSubject = self.currentSheet.detentData
        self.navigationCommands.send(.pop(destinationPageDetentPublisher: destinationDetentCurrentValueSubject))
    }

    func reset() {
        guard !self.sheets.isEmpty else {
            return
        }
        self.sheets = []
        self.navigationCommands.send(.popToRoot(rootDetentPublisher: self.emptySheetData.detentData))
    }
}

// MARK: - Previewable

extension SheetStore: Previewable {
    static let storeSetUpForPreviewing = SheetStore(emptySheetType: .search)
}

// MARK: - Detent

enum Detent: Hashable {
    case large
    case medium
    case fraction(CGFloat)
    case height(CGFloat)

    // MARK: Computed Properties

    var resolver: (any UISheetPresentationControllerDetentResolutionContext) -> CGFloat? {
        switch self {
        case .large: return { context in UISheetPresentationController.Detent.large().resolvedValue(in: context) }
        case .medium: return { context in UISheetPresentationController.Detent.medium().resolvedValue(in: context) }
        case let .fraction(fraction): return { context in context.maximumDetentValue * fraction }
        case let .height(height): return { _ in height }
        }
    }

    var uiKitDetent: UISheetPresentationController.Detent {
        .custom(identifier: self.identifier, resolver: self.resolver)
    }

    var identifier: UISheetPresentationController.Detent.Identifier {
        UISheetPresentationController.Detent.Identifier(rawValue: "\(self.hashValue)")
    }
}

// MARK: - NavigationCommand

enum NavigationCommand {
    case show(SheetData)
    case pop(destinationPageDetentPublisher: CurrentValueSubject<DetentData, Never>)
    case popToRoot(rootDetentPublisher: CurrentValueSubject<DetentData, Never>)
}

// MARK: - SheetType

enum SheetType: Hashable {
    case search
    case mapStyle
    case debugView
    case navigationAddSearchView
    case favorites
    case navigationPreview
    case pointOfInterest(ResolvedItem)
    case favoritesViewMore
    case editFavoritesForm(item: ResolvedItem, favoriteItem: FavoritesItem? = nil)

    // MARK: Computed Properties

    var initialDetentData: DetentData {
        switch self {
        case .search:
            DetentData(selectedDetent: .third, allowedDetents: [.small, .third, .large])
        case .mapStyle:
            DetentData(selectedDetent: .medium, allowedDetents: [.medium])
        case .debugView:
            DetentData(selectedDetent: .large, allowedDetents: [.large])
        case .navigationAddSearchView:
            DetentData(selectedDetent: .large, allowedDetents: [.large])
        case .favorites:
            DetentData(selectedDetent: .large, allowedDetents: [.large])
        case .navigationPreview:
            DetentData(selectedDetent: .nearHalf, allowedDetents: [.height(150), .nearHalf])
        case .pointOfInterest:
            DetentData(selectedDetent: .height(340), allowedDetents: [.height(340)])
        case .favoritesViewMore:
            DetentData(selectedDetent: .large, allowedDetents: [.large])
        case .editFavoritesForm:
            DetentData(selectedDetent: .large, allowedDetents: [.large])
        }
    }
}

// MARK: - SheetData

struct SheetData {
    let sheetType: SheetType
    let detentData: CurrentValueSubject<DetentData, Never>
}

// MARK: - DetentData

struct DetentData: Hashable {
    var selectedDetent: Detent
    let allowedDetents: [Detent]
}
