//
//  StreetView.swift
//  HudHud
//
//  Created by Patrick Kladek on 09.04.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreMotion
import SwiftUI

// MARK: - StreetView

struct StreetView: View {

	@ObservedObject var viewModel: MotionViewModel

	var body: some View {
		// please do not do catch here, a view is defined by its State, by executing an action during the calculation of a view, the view is no longer state defined
		// and/or you are are introducing a "hidden" state, "error" which is not defined
		// in the View's state model. For example, if I want to test the error view in
		// this view, I have no way of doing so from #Preview
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
