//
//  RatingSectionView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 09/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import OSLog
import SwiftUI

// MARK: - RatingSectionView

struct RatingSectionView: View {

    // MARK: Properties

    @State var store: RatingStore

    // MARK: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Customers Rating")
                    .hudhudFont(.headline)
                StarDisplayView(store: self.store)
            }
            .padding(.leading)
            .padding(.bottom, 16)

            VStack(alignment: .leading, spacing: 16) {
                Text("How was your experience?")
                    .hudhudFont(.headline)
                StarInteractionView(store: self.store)
            }
            .padding(.leading)
        }
    }
}

// MARK: - StarDisplayView

// Static Star Display View
struct StarDisplayView: View {

    // MARK: Properties

    let store: RatingStore

    // MARK: Content

    var body: some View {
        HStack(spacing: 12) {
            Text("\(self.store.state.staticRating, specifier: "%.1f")")
                .hudhudFont(.largeTitle)
                .foregroundStyle(Color.Colors.General._01Black)

            HStack(spacing: 4) {
                ForEach(1 ... 5, id: \.self) { index in
                    Image(self.store.state.staticRating < Double(index) ? .starOff : .starOn)
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
            Spacer()

            Text("\(self.store.state.ratingsCount) Ratings")
                .hudhudFont(.subheadline)
                .foregroundStyle(Color.Colors.General._02Grey)
                .padding(.trailing)
        }
    }
}

// MARK: - StarInteractionView

// Star Interaction View
struct StarInteractionView: View {

    // MARK: Properties

    let store: RatingStore

    // MARK: Content

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1 ... 5, id: \.self) { index in
                Image(index <= self.store.state.interactiveRating ? .starOn : .starEmpty)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .onTapGesture {
                        withAnimation {
                            self.store.reduce(action: .setInteractiveRating(index))
                        }
                        self.navigateToRateAndReview()
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let starIndex = Int((value.location.x / 50).rounded(.down))
                                let newRating = max(1, min(starIndex + 1, 5))
                                withAnimation {
                                    self.store.reduce(action: .setInteractiveRating(newRating))
                                }
                            }
                            .onEnded { _ in
                                self.navigateToRateAndReview()
                            }
                    )
            }
            Spacer()

            Text(self.store.state.ratingCategory?.description ?? "")
                .hudhudFont(.caption)
                .foregroundStyle(Color.Colors.General._02Grey)
                .padding(.trailing)
        }
    }
}

// MARK: - Private

private extension StarInteractionView {

    func navigateToRateAndReview() {
        Logger.navigationPath.info("Navigate to rate and review page")
    }
}

#Preview {
    RatingSectionView(store: RatingStore(staticRating: 4.1, ratingsCount: 508, interactiveRating: 0))
}
