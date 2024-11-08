//
//  MuteUIButton.swift
//  HudHud
//
//  Created by Ali Hilal on 03.11.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import FerrostarCore
import FerrostarCoreFFI
import SwiftUI

public struct MuteUIButton: View {

    // MARK: Properties

    let isMuted: Bool
    let action: () -> Void

    // MARK: Lifecycle

    public init(isMuted: Bool, action: @escaping () -> Void) {
        self.isMuted = isMuted
        self.action = action
    }

    // MARK: Content

    public var body: some View {
        Button(action: self.action) {
            Image(systemSymbol: self.isMuted ? .speakerSlashFill : .speakerWave2Fill)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
                .padding()
        }
        .foregroundColor(.black)
        .background(Color.white)
        .clipShape(Circle())
    }
}

#Preview {
    MuteUIButton(isMuted: true, action: {})

    MuteUIButton(isMuted: false, action: {})
}
