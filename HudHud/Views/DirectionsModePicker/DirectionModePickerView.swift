//
//  DirectionModePickerView.swift
//  HudHud
//
//  Created by Alaa . on 04/03/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct DirectionModePickerView: View {
	@State var directionModePickerData: [DierctionModePickerData]
	@State var selectedRoute: DierctionModePickerData = DierctionModePickerData(mode: "Car", sfSymbol: .car, duration: 1200, selected: false)
	var body: some View {
		HStack {
			ForEach(directionModePickerData.indices, id: \.self) { index in
				Button {
					switchMode(mode: directionModePickerData[index])
				} label: {
					Text(formatDuration(duration: directionModePickerData[index].duration))
				}
				.buttonStyle(DirectionModeButton(sfSymol: directionModePickerData[index].sfSymbol))
				.foregroundStyle(selectedRoute == directionModePickerData[index] ? Color.blue : Color.gray)
				.padding(.horizontal)
				.frame(minHeight: 70)
				.background(Color.white)
				.cornerRadius(10)
				.shadow(color: selectedRoute == directionModePickerData[index] ? .black.opacity(0.1) : .black.opacity(0), radius: 10, y: 10)
			}
		}
	}
	func formatDuration(duration: TimeInterval) -> String {
		let formatter = DateComponentsFormatter()
		formatter.allowedUnits = [.hour, .minute]
		formatter.unitsStyle = .brief
		if let formattedString = formatter.string(from: duration) {
			return formattedString
		} else {
			return "-"
		}
	}
	private func switchMode(mode: DierctionModePickerData) {
		withAnimation(.easeInOut) {
			selectedRoute = mode
		}
    }
}

#Preview {
    DirectionModePickerView(directionModePickerData: [
		DierctionModePickerData(mode: "Car", sfSymbol: .car, duration: 1200, selected: false),
		DierctionModePickerData(mode: "bus", sfSymbol: .bus, duration: 1700, selected: false),
		DierctionModePickerData(mode: "walk", sfSymbol: .figureWalk, duration: 3300, selected: false),
		DierctionModePickerData(mode: "bicycle", sfSymbol: .bicycle, duration: 2500, selected: false)
])
	.padding()
}
