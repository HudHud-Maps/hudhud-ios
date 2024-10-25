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
    private var currentDetentPublisher: CurrentValueSubject<DetentData, Never>?
    /// when the detent is being updated from the user, we do not want to do animation and change the detent again
    private var isDetentUpdatingFromUI = false

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
        self.view.backgroundColor = .white
        self.sheetUpdatesSubscription = self.sheetStore.navigationCommands.sink { [weak self] navigationCommand in
            switch navigationCommand {
            case let .show(sheetData):
                self?.show(sheetData)
            case let .pop(destinationSheetData):
                self?.pop(destinationSheetData: destinationSheetData)
            case let .popToRoot(rootSheetData):
                self?.popToRoot(rootSheetData: rootSheetData)
            }
        }
        self.sheetStore.start()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.sheetPresentationController?.delegate = self
        guard let currentDetentPublisher, let sheetPresentationController else { return }
        self.updateDetents(with: currentDetentPublisher.value, in: sheetPresentationController)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print(self.view.frame.height)
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

    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
        guard let selectedDetentIdentifier = sheetPresentationController.selectedDetentIdentifier,
              let currentDetentPublisher else { return }
        self.isDetentUpdatingFromUI = true
        defer { self.isDetentUpdatingFromUI = false }
        guard let selectedDetent = currentDetentPublisher.value
            .allowedDetents
            .first(where: { $0.identifier == selectedDetentIdentifier }) else { return }
        currentDetentPublisher.value.selectedDetent = selectedDetent
    }

    private func show(_ sheet: SheetData) {
        guard let sheetPresentationController else {
            assertionFailure("expected to have a sheet presentation controller")
            return
        }
        let viewController = self.buildSheet(for: sheet.sheetType)
        sheetPresentationController.animateChanges {
            self.updateDetents(with: sheet.detentData.value, in: sheetPresentationController)
            self.setNavigationTransition(sheet.sheetType.transition)
            self.pushViewController(viewController, animated: true)
        }
        self.observeChanges(in: sheet.detentData, andApplyIn: sheetPresentationController)
    }

    private func pop(destinationSheetData: SheetData) {
        guard let sheetPresentationController else {
            assertionFailure("expected to have a sheet presentation controller")
            return
        }
        sheetPresentationController.animateChanges {
            self.updateDetents(with: destinationSheetData.detentData.value, in: sheetPresentationController)
            self.popViewController(animated: true)
            self.setNavigationTransition(destinationSheetData.sheetType.transition)
        }
        self.observeChanges(in: destinationSheetData.detentData, andApplyIn: sheetPresentationController)
    }

    private func popToRoot(rootSheetData: SheetData) {
        guard let sheetPresentationController else {
            assertionFailure("expected to have a sheet presentation controller")
            return
        }
        sheetPresentationController.animateChanges {
            self.updateDetents(with: rootSheetData.detentData.value, in: sheetPresentationController)
            self.popToRootViewController(animated: true)
            self.setNavigationTransition(rootSheetData.sheetType.transition)
        }
        self.observeChanges(in: rootSheetData.detentData, andApplyIn: sheetPresentationController)
    }

    private func observeChanges(in detentPublisher: CurrentValueSubject<DetentData, Never>, andApplyIn sheetPresentationController: UISheetPresentationController) {
        self.currentDetentPublisher = detentPublisher
        self.sheetSubscription = detentPublisher.dropFirst().removeDuplicates().sink { [weak self] detentData in
            guard let self, !self.isDetentUpdatingFromUI else { return }
            sheetPresentationController.animateChanges {
                self.updateDetents(with: detentData, in: sheetPresentationController)
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
