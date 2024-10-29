//
//  DirectionModeButton.swift
//  HudHud
//
//  Created by Alaa . on 04/03/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SFSafeSymbols
import SwiftUI

struct DirectionModeButton: ButtonStyle {

    // MARK: Properties

    @State var sfSymol: SFSymbol = .car

    // MARK: Content

    // MARK: - Internal

    func makeBody(configuration: Configuration) -> some View {
        VStack {
            Image(systemSymbol: self.sfSymol)
                .font(.title)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            configuration.label
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity)
    }
}
