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
import NavigationTransition
import SwiftUI

// MARK: - SheetStore

/// this handles sheet states related to
/// * the navigation path
/// * the selected detent
/// * the allowed detent
/// * the sheet's visibility

@Observable @MainActor
final class SheetStore {

    // MARK: Properties

    let navigationCommands = PassthroughSubject<NavigationCommand, Never>()
    var isShown = CurrentValueSubject<Bool, Never>(true)
    var safeAreaInsets = EdgeInsets()
    private(set) var sheetHeight: CGFloat = 0

    private let makeSheetProvider: (SheetContext) -> any SheetProvider

    private var sheets: [SheetData] = []

    private var emptySheetData: SheetData
    private var updateSheetHeightSubscription: AnyCancellable?

    // MARK: Computed Properties

    var rawSheetheight: CGFloat = 0 {
        didSet {
            self.sheetHeight = self.computeSheetHeight()
        }
    }

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

    init(emptySheetType: SheetType, makeSheetProvider: @escaping (SheetContext) -> any SheetProvider) {
        self.makeSheetProvider = makeSheetProvider
        self.emptySheetData = SheetData(
            sheetType: emptySheetType,
            detentData: CurrentValueSubject<DetentData, Never>(emptySheetType.initialDetentData),
            sheetProvider: EmptySheetProvider()
        )
        self.emptySheetData = self.makeSheet(from: emptySheetType)
        self.updateSheetHeightSubscription = self.isShown.sink { [weak self] _ in
            guard let self else { return }
            self.sheetHeight = self.computeSheetHeight()
        }
    }

    // MARK: Functions

    func start() {
        self.navigationCommands.send(.show(self.emptySheetData))
    }

    func show(_ sheetType: SheetType) {
        let sheetData = self.makeSheet(from: sheetType)
        self.sheets.append(sheetData)
        self.navigationCommands.send(.show(sheetData))
    }

    func popSheet() {
        guard !self.sheets.isEmpty else {
            return
        }
        _ = self.sheets.popLast()
        self.navigationCommands.send(.pop(destinationSheetData: self.currentSheet))
    }

    func popToRoot() {
        guard !self.sheets.isEmpty else {
            return
        }
        self.sheets = []
        self.navigationCommands.send(.popToRoot(rootSheetData: self.emptySheetData))
    }
}

// MARK: - Private

private extension SheetStore {

    func makeSheet(from sheetType: SheetType) -> SheetData {
        let detentCurrentValueSubject = CurrentValueSubject<DetentData, Never>(sheetType.initialDetentData)
        let context = SheetContext(sheetStore: self, sheetType: sheetType, detentData: detentCurrentValueSubject)
        let sheetProvider = self.makeSheetProvider(context)
        return SheetData(
            sheetType: sheetType,
            detentData: detentCurrentValueSubject,
            sheetProvider: sheetProvider
        )
    }

    func computeSheetHeight() -> CGFloat {
        if self.isShown.value {
            self.rawSheetheight - self.safeAreaInsets.bottom
        } else {
            0
        }
    }
}

// MARK: - Previewable

extension SheetStore: Previewable {
    static let storeSetUpForPreviewing = SheetStore(
        emptySheetType: .search,
        makeSheetProvider: sheetProviderBuilder(
            userLocationStore: .storeSetUpForPreviewing,
            debugStore: DebugStore(),
            mapStore: .storeSetUpForPreviewing,
            routesPlanMapDrawer: RoutesPlanMapDrawer(),
            hudhudMapLayerStore: HudHudMapLayerStore(),
            routingStore: .storeSetUpForPreviewing,
            streetViewStore: .storeSetUpForPreviewing
        )
    )
    static let storeSetUpForPreviewingPOI = SheetStore(
        emptySheetType: .pointOfInterest(.ketchup),
        makeSheetProvider: sheetProviderBuilder(
            userLocationStore: .storeSetUpForPreviewing,
            debugStore: DebugStore(),
            mapStore: .storeSetUpForPreviewing,
            routesPlanMapDrawer: RoutesPlanMapDrawer(),
            hudhudMapLayerStore: HudHudMapLayerStore(),
            routingStore: .storeSetUpForPreviewing,
            streetViewStore: .storeSetUpForPreviewing
        )
    )
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
    case pop(destinationSheetData: SheetData)
    case popToRoot(rootSheetData: SheetData)
}

// MARK: - SheetType

enum SheetType {
    case search
    case mapStyle
    case debugView
    case navigationAddSearchView((ResolvedItem) -> Void)
    case favorites
    case navigationPreview
    case pointOfInterest(ResolvedItem)
    case routePlanner(RoutePlannerStore)
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
            DetentData(selectedDetent: .height(190), allowedDetents: [.height(140), .height(190), .height(600), .large])
        case .routePlanner:
            DetentData(selectedDetent: .height(100), allowedDetents: [.height(100)])
        case .favoritesViewMore:
            DetentData(selectedDetent: .large, allowedDetents: [.large])
        case .editFavoritesForm:
            DetentData(selectedDetent: .large, allowedDetents: [.large])
        }
    }

    var transition: AnyNavigationTransition {
        switch self {
        case .favoritesViewMore, .editFavoritesForm, .favorites:
            .default
        default:
            .fade(.cross)
        }
    }
}

// MARK: - SheetContext

struct SheetContext {
    let sheetStore: SheetStore
    let sheetType: SheetType
    let detentData: CurrentValueSubject<DetentData, Never>
}

// MARK: - SheetData

struct SheetData {
    let sheetType: SheetType
    let detentData: CurrentValueSubject<DetentData, Never>
    let sheetProvider: any SheetProvider
}

// MARK: - DetentData

struct DetentData: Hashable {
    var selectedDetent: Detent
    let allowedDetents: [Detent]
}
