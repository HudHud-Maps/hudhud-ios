//
//  DirectionModePickerView.swift
//  HudHud
//
//  Created by Alaa . on 04/03/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct DirectionModePickerView: View {
    @State var directionModePickerData: [DirectionModePickerData]
    @State var selectedRoute = DirectionModePickerData(mode: .car, duration: 1200)
    var formatter = Formatters()

    var body: some View {
        HStack {
            ForEach(self.directionModePickerData) { mode in
                Button {
                    self.switchMode(mode: mode)
                } label: {
                    Text(self.formatter.formatDuration(duration: mode.duration))
                }
                .buttonStyle(DirectionModeButton(sfSymol: mode.mode.iconName))
                .foregroundStyle(self.selectedRoute == mode ? Color.blue : Color.gray)
                .padding(.horizontal)
                .frame(minHeight: 70)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: self.selectedRoute == mode ? .black.opacity(0.1) : .black.opacity(0), radius: 10, y: 10)
            }
        }
    }

    // MARK: - Private

    private func switchMode(mode: DirectionModePickerData) {
        withAnimation(.easeInOut) {
            self.selectedRoute = mode
        }
    }
}

#Preview {
    DirectionModePickerView(directionModePickerData: [
        DirectionModePickerData(mode: .car, duration: 1200),
        DirectionModePickerData(mode: .bus, duration: 1800),
        DirectionModePickerData(mode: .walk, duration: 2600),
        DirectionModePickerData(mode: .bicycle, duration: 2200)
    ])
    .padding()
}
