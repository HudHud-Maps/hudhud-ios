//
//  SheetContainerViewController.swift
//  HudHud
//
//  Created by Naif Alrashed on 17/04/1446 AH.
//  Copyright © 1446 AH HudHud. All rights reserved.
//

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

// MARK: - SheetContainerView

struct SheetContainerView<Content: View, RootView: View>: UIViewControllerRepresentable {

    // MARK: Properties

    var sheetStore: SheetStore
    @ViewBuilder let sheetToView: (SheetViewData) -> Content
    @ViewBuilder let rootSheetView: () -> RootView

    // MARK: Functions

    func makeUIViewController(context: Context) -> UINavigationController {
        let sheetContainerViewController = UINavigationController()
        sheetContainerViewController.sheetPresentationController!.largestUndimmedDetentIdentifier = .medium
        sheetContainerViewController.presentationController?.delegate = context.coordinator
        return sheetContainerViewController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        context.coordinator.applyChange(in: uiViewController)
    }

    func makeCoordinator() -> SheetContainerCoordinator {
        SheetContainerCoordinator(sheetStore: self.sheetStore, sheetToView: self.sheetToView, rootSheetView: self.rootSheetView)
    }
}

// MARK: - SheetContainerView.SheetContainerCoordinator

extension SheetContainerView {
//    @MainActor
    final class SheetContainerCoordinator: NSObject, UISheetPresentationControllerDelegate {

        // MARK: Properties

        var sheets: [SheetViewData] = []
        let sheetStore: SheetStore
        let sheetToView: (SheetViewData) -> Content
        let rootSheetView: () -> RootView

        // MARK: Lifecycle

        init(
            sheetStore: SheetStore,
            sheetToView: @escaping ((SheetViewData) -> Content),
            rootSheetView: @escaping () -> RootView
        ) {
            self.sheetStore = sheetStore
            self.sheetToView = sheetToView
            self.rootSheetView = rootSheetView
        }

        deinit {
            print("deinit SheetContainerCoordinator")
        }

        // MARK: Functions

        func applyChange(in navigationController: UINavigationController) {
            if self.sheets.count < self.sheetStore.sheets.count {
                self.push(self.sheetStore.sheets.last!, in: navigationController)
            } else if self.sheets.count > self.sheetStore.sheets.count {
                self.pop(self.sheets.last!, in: navigationController)
            } else {
                navigationController.sheetPresentationController!.animateChanges {
                    navigationController.sheetPresentationController!.detents = self.sheetStore.sheets.last?.uiKitAllowedDetents.map(\.uiKitDetent) ?? self.sheetStore.uiKitEmptySheetAllowedDetents.map(\.uiKitDetent)
                    navigationController.sheetPresentationController!.selectedDetentIdentifier = self.sheetStore.sheets.last?.uiKitSelectedDetent.identifier ?? self.sheetStore.uiKitEmptySheetSelectedDetent.identifier
                    if self.sheets.isEmpty, self.sheetStore.sheets.isEmpty, navigationController.viewControllers.isEmpty {
                        let rootView = self.rootSheetView()
                        let viewController = UIHostingController(rootView: rootView)
                        navigationController.pushViewController(viewController, animated: false)
                    }
                }
            }
            self.sheets = self.sheetStore.sheets
        }

        func presentationControllerShouldDismiss(_: UIPresentationController) -> Bool {
            false
        }

        private func push(_ sheet: SheetViewData, in navigationController: UINavigationController) {
            let view = self.sheetToView(sheet)
            let viewController = UIHostingController(rootView: view)
            guard let sheetPresentationController = navigationController.sheetPresentationController else {
                fatalError("expected to have a sheet presentation controller")
            }
            sheetPresentationController.animateChanges {
                sheetPresentationController.detents = sheet.uiKitAllowedDetents.map(\.uiKitDetent)
                sheetPresentationController.selectedDetentIdentifier = sheet.uiKitSelectedDetent.identifier
                navigationController.pushViewController(viewController, animated: true)
            }
        }

        private func pop(_: SheetViewData, in navigationController: UINavigationController) {
            navigationController.popViewController(animated: true)
        }

        private func changeDetent() {}
    }
}
