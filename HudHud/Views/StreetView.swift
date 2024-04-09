//
//  StreetView.swift
//  HudHud
//
//  Created by Patrick Kladek on 09.04.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreMotion
import SwiftUI

// MARK: - DebugStreetView

struct StreetView: View {

	@ObservedObject var viewModel: MotionViewModel

	var body: some View {
		StreetViewWebView(viewModel: self.viewModel)
			.frame(maxWidth: .infinity, idealHeight: 300, maxHeight: self.viewModel.size == .compact ? 300 : .infinity)
			.clipShape(RoundedRectangle(cornerRadius: 12))
			.onTapGesture {
				self.viewModel.size.selectNext()
			}
			.padding(.horizontal)
			.animation(.easeInOut, value: self.viewModel.size)
	}
}

#Preview {
	Rectangle()
		.fill(Color.yellow)
		.ignoresSafeArea()
		.safeAreaInset(edge: .top, alignment: .center) {
			DebugStreetView(viewModel: .storeSetUpForPreviewing)
		}
}
