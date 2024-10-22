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

class MapViewController<SheetContent: View>: UIViewController, MapViewHostViewController {

    // MARK: Properties

    let mapView: MLNMapView

    private let sheetStore: SheetStore
    private let sheetToView: (SheetType) -> SheetContent
    private let emptySheet: SheetElement
    private var sheetSubscription: AnyCancellable?

    // MARK: Lifecycle

    init(
        sheetStore: SheetStore,
        emptySheet: SheetElement,
        styleURL: URL,
        sheetToView: @escaping (SheetType) -> SheetContent
    ) {
        self.mapView = MLNMapView(frame: .zero, styleURL: styleURL)
        self.emptySheet = emptySheet
        self.sheetToView = sheetToView
        self.sheetStore = sheetStore
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

    override func viewDidLoad() {
        super.viewDidLoad()

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) {
            self.sheetStore.isShown.toggle()
        }

//        withObservationTracking {
//            _ = self.sheetStore.isShown
//        } onChange: { [weak self] in
//            Task {
//                await self?.handleSheetChange()
//            }
//        }
        self.handleSheetChange()
    }

    // MARK: Functions

    private func handleSheetChange() {
        if self.sheetStore.isShown, self.presentedViewController == nil {
            let viewController = SheetContainerViewController(emptySheet: self.emptySheet, sheetToView: self.sheetToView)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.present(viewController, animated: true)
            }
        } else if !self.sheetStore.isShown, let presentedViewController {
            presentedViewController.dismiss(animated: true, completion: nil)
        }
    }
}
