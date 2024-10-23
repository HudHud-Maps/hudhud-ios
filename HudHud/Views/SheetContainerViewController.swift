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

    private func pop(destinationPageDetentPublisher: CurrentValueSubject<DetentData, Never>) {
        guard let sheetPresentationController else {
            assertionFailure("expected to have a sheet presentation controller")
            return
        }
        sheetPresentationController.animateChanges {
            sheetPresentationController.detents = destinationPageDetentPublisher.value.allowedDetents.map(\.uiKitDetent)
            sheetPresentationController.selectedDetentIdentifier = destinationPageDetentPublisher.value.selectedDetent.identifier
            self.popViewController(animated: true)
        }
        self.sheetSubscription = destinationPageDetentPublisher.dropFirst().removeDuplicates().sink { pageDetent in
            sheetPresentationController.animateChanges {
                sheetPresentationController.detents = pageDetent.allowedDetents.map(\.uiKitDetent)
                sheetPresentationController.selectedDetentIdentifier = pageDetent.selectedDetent.identifier
            }
        }
    }

    private func buildSheet(for sheetType: SheetType) -> UIViewController {
        let view = self.sheetToView(sheetType)
        let viewController = UIHostingController(rootView: view)
        return viewController
    }
}
