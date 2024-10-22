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
}

import Combine

// MARK: - DetentData

struct DetentData: Hashable {
    var selectedDetent: Detent
    let allowedDetents: [Detent]
}

// MARK: - SheetElement

@MainActor
protocol SheetElement {
    var sheetType: SheetType { get }
    var detentData: CurrentValueSubject<DetentData, Never> { get }
}

// MARK: - SheetContainerViewController

final class SheetContainerViewController<Content: View>: UINavigationController, UISheetPresentationControllerDelegate {

    // MARK: Properties

    private var sheets: [SheetElement] = []
    private let emptySheet: SheetElement
    private let sheetToView: (SheetType) -> Content
    private var sheetSubscription: AnyCancellable?
    private var _allowedDetents: CurrentValueSubject<[Detent], Never>
    private var _selectedDetent: CurrentValueSubject<Detent, Never>

    // MARK: Computed Properties

    var allowedDetents: any Publisher<[Detent], Never> { self._allowedDetents }
    var selectedDetent: any Publisher<Detent, Never> { self._selectedDetent }

    // MARK: Lifecycle

    init(
        emptySheet: SheetElement,
        sheetToView: @escaping (SheetType) -> Content
    ) {
        self.emptySheet = emptySheet
        self.sheetToView = sheetToView
        self._allowedDetents = CurrentValueSubject(emptySheet.detentData.value.allowedDetents)
        self._selectedDetent = CurrentValueSubject(emptySheet.detentData.value.selectedDetent)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        print("deinit SheetContainerCoordinator")
    }

    // MARK: Overridden Functions

    override func viewDidLoad() {
        super.viewDidLoad()
        self.sheetPresentationController?.delegate = self
        self.show(self.emptySheet)
    }

    // MARK: Functions

    func presentationControllerShouldDismiss(_: UIPresentationController) -> Bool {
        false
    }

    private func show(_ sheet: SheetElement) {
        guard let sheetPresentationController else {
            assertionFailure("expected to have a sheet presentation controller")
            return
        }
        sheetPresentationController.animateChanges {
            sheetPresentationController.detents = sheet.detentData.value.allowedDetents.map(\.uiKitDetent)
            sheetPresentationController.selectedDetentIdentifier = sheet.detentData.value.selectedDetent.identifier
            let viewController = self.viewController(for: sheet)
            self.pushViewController(viewController, animated: true)
        }
        self.sheetSubscription = sheet.detentData.dropFirst().removeDuplicates().sink { detentData in
            sheetPresentationController.animateChanges {
                sheetPresentationController.detents = detentData.allowedDetents.map(\.uiKitDetent)
                sheetPresentationController.selectedDetentIdentifier = detentData.selectedDetent.identifier
            }
        }
    }

    private func popSheet() {
        guard self.viewControllers.count > 2, let sheetPresentationController else {
            return
        }
    }

    private func viewController(for sheet: SheetElement) -> UIViewController {
        let view = self.sheetToView(sheet.sheetType)
        let viewController = UIHostingController(rootView: view)
        return viewController
    }
}
