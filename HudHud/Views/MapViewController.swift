//
//  MapViewController.swift
//  HudHud
//
//  Created by Naif Alrashed on 18/04/1446 AH.
//  Copyright © 1446 AH HudHud. All rights reserved.
//

import Combine
import MapLibre
import MapLibreSwiftUI
import SwiftUI
import UIKit

class MapViewController: UIViewController, MapViewHostViewController {

    // MARK: Properties

    let mapView: MLNMapView

    private let sheetStore: SheetStore
    private let sheetViewController: UIViewController
    private var sheetSubscription: AnyCancellable?
    private var isFirstAppear = true

    // MARK: Lifecycle

    init(
        sheetStore: SheetStore,
        styleURL: URL,
        sheetToView: @escaping (SheetType) -> some View
    ) {
        self.mapView = MLNMapView(frame: .zero, styleURL: styleURL)
        self.sheetStore = sheetStore
        self.sheetViewController = SheetContainerViewController(
            sheetStore: sheetStore,
            sheetToView: sheetToView
        )
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Overridden Functions

    override func loadView() {
        self.view = self.mapView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if self.isFirstAppear {
            self.isFirstAppear = false
            self.handleSheetChange()
        }
    }

    // MARK: Functions

    private func handleSheetChange() {
        if self.sheetStore.isShown, self.presentedViewController == nil {
            self.present(self.sheetViewController, animated: true)
        } else if !self.sheetStore.isShown, self.presentedViewController != nil {
            self.sheetViewController.dismiss(animated: true, completion: nil)
        }
    }
}
