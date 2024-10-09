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

    var ratingModel: RatingStore

    // MARK: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Customers Rating")
                    .hudhudFont(.headline)
                StarDisplayView(ratingModel: self.ratingModel)
            }
            .padding(.leading)
            .padding(.bottom, 16)

            VStack(alignment: .leading, spacing: 16) {
                Text("How was your experience?")
                    .hudhudFont(.headline)
                StarInteractionView(ratingModel: self.ratingModel)
            }
            .padding(.leading)
        }
    }
}

// MARK: - StarDisplayView

// Static Star Display View
struct StarDisplayView: View {

    // MARK: Properties

    var ratingModel: RatingStore

    // MARK: Content

    var body: some View {
        HStack(spacing: 12) {
            Text("\(self.ratingModel.staticRating, specifier: "%.1f")")
                .hudhudFont(.largeTitle)
                .foregroundStyle(Color.Colors.General._01Black)

            // Star icons
            HStack(spacing: 4) {
                ForEach(1 ... 5, id: \.self) { index in
                    Image(self.ratingModel.staticRating < Double(index) ? .starOff : .starOn)
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
            Spacer()
            Text("\(self.ratingModel.ratingsCount) Ratings")
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

    var ratingModel: RatingStore

    // MARK: Content

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1 ... 5, id: \.self) { index in
                Image(index <= self.ratingModel.interactiveRating ? .starOn : .starEmpty)
                    .resizable()
                    .frame(width: 50, height: 50)
                    .onTapGesture {
                        withAnimation {
                            self.ratingModel.interactiveRating = index
                        }
                        // Navigate to rate and review page
                        Logger.navigationPath.info("Navigate to rate and review page")
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let starIndex = Int((value.location.x / 50).rounded(.down))
                                let newRating = max(1, min(starIndex + 1, 5))
                                withAnimation {
                                    self.ratingModel.interactiveRating = newRating
                                }
                            }
                            .onEnded { _ in
                                // Navigate to rate and review page
                                Logger.navigationPath.info("Navigate to rate and review page")
                            }
                    )
            }
            Spacer()

            Text("\(self.ratingModel.getText())")
                .hudhudFont(.caption)
                .foregroundStyle(Color.Colors.General._02Grey)
                .padding(.trailing)
        }
    }
}

#Preview {
    RatingSectionView(ratingModel: RatingStore(staticRating: 4.1, ratingsCount: 508, interactiveRating: 0))
}
