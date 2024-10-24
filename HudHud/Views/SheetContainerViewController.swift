//
//  SheetContainerViewController.swift
//  HudHud
//
//  Created by Naif Alrashed on 17/04/1446 AH.
//  Copyright © 1446 AH HudHud. All rights reserved.
//

import BackendService
import Combine
import SwiftUI
import UIKit

// MARK: - SheetContainerViewController

final class SheetContainerViewController<Content: View>: UINavigationController, UISheetPresentationControllerDelegate {

    // MARK: Properties

    private let sheetToView: (SheetType) -> Content
    private var sheetSubscription: AnyCancellable?
    private var sheetUpdatesSubscription: AnyCancellable?
    private let sheetStore: SheetStore

    // MARK: Lifecycle

    init(
        sheetStore: SheetStore,
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
            case let .pop(destinationPageDetentPublisher):
                self?.pop(destinationPageDetentPublisher: destinationPageDetentPublisher)
            case let .popToRoot(rootDetentPublisher):
                self?.popToRoot(rootDetentPublisher: rootDetentPublisher)
            }
        }
        self.sheetStore.start()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.sheetStore.rawSheetheight = self.view.frame.height
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        self.sheetStore.safeAreaInsets = EdgeInsets(
            top: self.view.safeAreaInsets.top,
            leading: self.view.safeAreaInsets.left,
            bottom: self.view.safeAreaInsets.bottom,
            trailing: self.view.safeAreaInsets.right
        )
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
            self.updateDetents(with: sheet.detentData.value, in: sheetPresentationController)
            self.pushViewController(viewController, animated: true)
        }
        self.sheetSubscription = sheet.detentData.dropFirst().removeDuplicates().sink { detentData in
            sheetPresentationController.animateChanges {
                self.updateDetents(with: detentData, in: sheetPresentationController)
            }
        }
    }

    private func pop(destinationPageDetentPublisher: CurrentValueSubject<DetentData, Never>) {
        guard let sheetPresentationController else {
            assertionFailure("expected to have a sheet presentation controller")
            return
        }
        sheetPresentationController.animateChanges {
            self.updateDetents(with: destinationPageDetentPublisher.value, in: sheetPresentationController)
            self.popViewController(animated: true)
        }
        self.sheetSubscription = destinationPageDetentPublisher.dropFirst().removeDuplicates().sink { pageDetent in
            sheetPresentationController.animateChanges {
                self.updateDetents(with: pageDetent, in: sheetPresentationController)
            }
        }
    }

    private func popToRoot(rootDetentPublisher: CurrentValueSubject<DetentData, Never>) {
        guard let sheetPresentationController else {
            assertionFailure("expected to have a sheet presentation controller")
            return
        }
        sheetPresentationController.animateChanges {
            self.updateDetents(with: rootDetentPublisher.value, in: sheetPresentationController)
            self.popToRootViewController(animated: true)
        }
        self.sheetSubscription = rootDetentPublisher.dropFirst().removeDuplicates().sink { rootDetent in
            sheetPresentationController.animateChanges {
                self.updateDetents(with: rootDetent, in: sheetPresentationController)
            }
        }
    }

    private func updateDetents(with detentData: DetentData, in sheetPresentationController: UISheetPresentationController) {
        sheetPresentationController.detents = detentData.allowedDetents.map(\.uiKitDetent)
        sheetPresentationController.selectedDetentIdentifier = detentData.selectedDetent.identifier
        let currentScreenHeight = UIScreen.main.bounds.height
        let largestDetent = detentData.allowedDetents
            .map {
                ComparableDetent(detent: $0, currentViewHeight: currentScreenHeight)
            }
            .sorted()
            .last?.detent
        sheetPresentationController.largestUndimmedDetentIdentifier = largestDetent?.identifier
    }

    private func buildSheet(for sheetType: SheetType) -> UIViewController {
        let view = self.sheetToView(sheetType)
        let viewController = UIHostingController(rootView: view)
        return viewController
    }
}

// MARK: - ComparableDetent

struct ComparableDetent: Comparable {

    // MARK: Properties

    let detent: Detent
    let currentViewHeight: CGFloat

    // MARK: Computed Properties

    var height: CGFloat {
        switch self.detent {
        case .large:
            self.currentViewHeight
        case .medium:
            self.currentViewHeight / 2
        case let .fraction(fraction):
            self.currentViewHeight * fraction
        case let .height(height):
            height
        }
    }

    // MARK: Static Functions

    static func < (lhs: ComparableDetent, rhs: ComparableDetent) -> Bool {
        lhs.height < rhs.height
    }
}
