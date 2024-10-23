//
//  SheetContainerViewController.swift
//  HudHud
//
//  Created by Naif Alrashed on 17/04/1446 AH.
//  Copyright © 1446 AH HudHud. All rights reserved.
//

import BackendService
import SwiftUI
import UIKit

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
}

// MARK: - MySheet

@Observable
@MainActor
final class MySheet {

    // MARK: Properties

    let navigationCommands = PassthroughSubject<NavigationCommand, Never>()
    var isShown = true

    private var sheets: [SheetData] = []

    private let emptySheetData: SheetData

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
}

// MARK: - Previewable

extension MySheet: Previewable {
    static var storeSetUpForPreviewing: MySheet = .init(emptySheetType: .search)
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

import Combine

// MARK: - DetentData

struct DetentData: Hashable {
    var selectedDetent: Detent
    let allowedDetents: [Detent]
}

// MARK: - SheetContainerViewController

final class SheetContainerViewController<Content: View>: UINavigationController, UISheetPresentationControllerDelegate {

    // MARK: Properties

    private let sheetToView: (SheetType) -> Content
    private var sheetSubscription: AnyCancellable?
    private var sheetUpdatesSubscription: AnyCancellable?
    private let sheetStore: MySheet

    // MARK: Lifecycle

    init(
        sheetStore: MySheet,
        sheetToView: @escaping (SheetType) -> Content
    ) {
        self.sheetStore = sheetStore
        self.sheetToView = sheetToView
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Overridden Functions

    override func viewDidLoad() {
        super.viewDidLoad()
        self.sheetPresentationController?.delegate = self
        self.sheetUpdatesSubscription = self.sheetStore.navigationCommands.sink { [weak self] navigationCommand in
            switch navigationCommand {
            case let .show(sheetData):
                self?.show(sheetData)
            }
        }
        self.sheetStore.start()
    }

    // MARK: Functions

    func presentationControllerShouldDismiss(_: UIPresentationController) -> Bool {
        false
    }

    private func show(_ sheet: SheetData) {
        guard let sheetPresentationController else {
            assertionFailure("expected to have a sheet presentation controller")
            return
        }
        let viewController = self.buildSheet(for: sheet.sheetType)
        sheetPresentationController.animateChanges {
            sheetPresentationController.detents = sheet.detentData.value.allowedDetents.map(\.uiKitDetent)
            sheetPresentationController.selectedDetentIdentifier = sheet.detentData.value.selectedDetent.identifier
            self.pushViewController(viewController, animated: true)
        }
        self.sheetSubscription = sheet.detentData.dropFirst().removeDuplicates().sink { detentData in
            sheetPresentationController.animateChanges {
                sheetPresentationController.detents = detentData.allowedDetents.map(\.uiKitDetent)
                sheetPresentationController.selectedDetentIdentifier = detentData.selectedDetent.identifier
            }
        }
    }

    private func buildSheet(for sheetType: SheetType) -> UIViewController {
        let view = self.sheetToView(sheetType)
        let viewController = UIHostingController(rootView: view)
        return viewController
    }
}
