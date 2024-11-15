//
//  RateNavigationView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 27/06/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import OSLog
import SwiftUI

// MARK: - RateNavigationView

struct RateNavigationView: View {

    let faces: [ImageResource] = [
        .MOOD_SMILE_5,
        .MOOD_SMILE_4,
        .MOOD_SMILE_3,
        .MOOD_SMILE_2,
        .MOOD_SMILE_1
    ]
    var sheetStore: SheetStore
    @State private var selecteFace: Int?
    @State private var currentTask: Task<Void, Never>?
    @State private var animate = false

    var selectedFace: ((Int) -> Void)?
    let onDismiss: () -> Void
    var smallScreen: Bool {
        UIScreen.main.bounds.height < 700
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .center) {
                Image(systemSymbol: .checkmarkCircleFill)
                    .resizable()
                    .foregroundColor(.green)
                    .scaledToFit()
                    .frame(width: 75, height: 75)
                    .symbolEffect(.bounce.down, value: self.animate)
                VStack(alignment: .center, spacing: 5) {
                    Text("You Have Arrived")
                        .hudhudFont(.title)
                    Text("Help improve HudHud maps.")
                        .hudhudFont(.subheadline)
                        .foregroundColor(.gray)
                    Text("How was the navigation on this trip?")
                        .hudhudFont(.subheadline)
                        .foregroundColor(.gray)
                }
                HStack(spacing: 20) {
                    ForEach(self.faces.indices, id: \.self) { index in
                        Image(self.faces[index])
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(index == self.selecteFace ? .green : .gray)
                            .onTapGesture {
                                self.selectFace(index)
                            }
                    }
                }
                .padding(.top)
                .onChange(of: self.sheetStore.selectedDetent) {
                    if self.sheetStore.selectedDetent == .small {
                        self.onDismiss()
                    }
                }
            }
            .padding(.top)
            .onAppear { // if smaller screen = bigger sheet to fit content
                self.sheetStore.currentSheet.detentData.value = if self.smallScreen {
                    DetentData(selectedDetent: .nearHalf, allowedDetents: [.nearHalf])
                } else {
                    DetentData(selectedDetent: .third, allowedDetents: [.small, .third])
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        self.onDismiss()
                    }, label: {
                        ZStack {
                            Circle()
                                .fill(.quaternary)
                                .frame(width: 30, height: 30)

                            Image(systemSymbol: .xmark)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(8)
                        .contentShape(Circle())
                    })
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel(Text("Close", comment: "Accessibility label instead of x"))
                }
            }
            .edgesIgnoringSafeArea(.vertical)
        }
    }
}

// MARK: - Private

private extension RateNavigationView {

    func selectFace(_ face: Int) {
        self.animate.toggle()
        self.currentTask?.cancel()
        self.selecteFace = face
        // Create a new task to dismiss the view after 2 seconds
        self.currentTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                if !Task.isCancelled {
                    withAnimation {
                        self.selectedFace?(face)
                    }
                }
            }
        }
    }
}

#Preview {
    RateNavigationView(sheetStore: .storeSetUpForPreviewing, selectedFace: { face in
        Logger.navigationViewRating.log("\(face)")
    }, onDismiss: {})
}
