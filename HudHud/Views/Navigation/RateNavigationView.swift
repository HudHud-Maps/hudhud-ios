//
//  RateNavigationView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 27/06/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct RateNavigationView: View {

    let faces: [UIImage] = [
        UIImage(named: "MOOD_SMILE-1")!,
        UIImage(named: "MOOD_SMILE-2")!,
        UIImage(named: "MOOD_SMILE-3")!,
        UIImage(named: "MOOD_SMILE-4")!,
        UIImage(named: "MOOD_SMILE-5")!
    ]

    @Environment(\.presentationMode) var presentationMode
    @State private var selecteFace: Int?
    @State private var currentTask: Task<Void, Never>?
    @State private var animate = false
    var selectedFace: ((Int) -> Void)?

    var body: some View {
        VStack {
            Image(systemSymbol: .checkmarkCircleFill)
                .resizable()
                .foregroundColor(.green)
                .scaledToFit()
                .frame(width: 75, height: 75)
                .padding(.top)
                .backport.symbolEffect(animate: self.animate)

            Text("You Have Arrived")
                .font(.title)
                .bold()
            Text("Help improve HudHud maps.")
                .font(.subheadline)
                .foregroundColor(.gray)
            Text("How was the navigation on this trip?")
                .font(.subheadline)
                .foregroundColor(.gray)
            HStack(spacing: 20) {
                ForEach(self.faces.indices, id: \.self) { index in

                    Image(uiImage: self.faces[index])
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(index == self.selecteFace ? .green : .gray)
                        .onTapGesture {
                            self.selectFace(index)
                        }
                }
            }
        }
    }

    // MARK: - Private

    private func selectFace(_ face: Int) {
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
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

}

#Preview {
    RateNavigationView(selectedFace: { face in
        print(face)
    })
}
