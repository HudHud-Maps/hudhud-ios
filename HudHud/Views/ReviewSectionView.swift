//
//  ReviewSectionView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 10/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - ReviewSectionView

struct ReviewSectionView: View {

    // MARK: Properties

    let review: Review

    // MARK: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            UserView(review: self.review)

            RatingsView(review: self.review)

            // Review Text
            Text(self.review.reviewText)
                .hudhudFont(.body)
                .lineLimit(nil)
                .foregroundStyle(Color.Colors.General._01Black)

            ImageView(review: self.review)
                .padding(.vertical, 2)
            BottomBar(isUseful: self.review.isUseful, usefulCount: self.review.usefulCount)

            Divider()
        }
        .padding()
    }
}

// MARK: - UserView

struct UserView: View {

    // MARK: Properties

    let review: Review

    // MARK: Content

    var body: some View {
        HStack {
            Image(systemSymbol: .personCircleFill)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(self.review.username)
                    .hudhudFont(.headline)
                Text("From \(self.review.userType)")
                    .hudhudFont(.subheadline)
                    .foregroundStyle(Color.Colors.General._02Grey)
            }
        }
    }
}

// MARK: - RatingsView

struct RatingsView: View {

    // MARK: Properties

    let review: Review

    // MARK: Content

    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: 1) {
                ForEach(1 ... 5, id: \.self) { index in
                    Image(self.review.rating < Int(index) ? .starOff : .starOn)
                        .resizable()
                        .frame(width: 14, height: 14)
                }
            }
            Text(self.review.date)
                .hudhudFont(.footnote)
                .foregroundStyle(Color.Colors.General._02Grey)
        }
    }
}

// MARK: - ImageView

struct ImageView: View {

    // MARK: Properties

    let review: Review

    @State private var selectedMedia: URL?

    // MARK: Content

    var body: some View {
        VStack {
            if self.review.images.count == 1, let image = review.images.first {
                AsyncImage(url: image) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: .infinity, height: 168)
                        .clipped()
                        .contentShape(.rect)
                } placeholder: {
                    ProgressView()
                        .progressViewStyle(.automatic)
                        .background(.secondary)
                        .cornerRadius(10)
                }
                .background(.secondary)
                .cornerRadius(10)
                .frame(width: .infinity, height: 168)
                .onTapGesture {
                    self.selectedMedia = image
                }
            } else {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(self.review.images, id: \.self) { mediaURL in
                            AsyncImage(url: mediaURL) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                            } placeholder: {
                                ProgressView()
                                    .progressViewStyle(.automatic)
                                    .frame(width: 120, height: 120)
                                    .background(.secondary)
                                    .cornerRadius(10)
                            }
                            .background(.secondary)
                            .cornerRadius(10)
                            .onTapGesture {
                                self.selectedMedia = mediaURL
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .sheet(item: self.$selectedMedia) { mediaURL in
            FullPageImage(
                mediaURL: mediaURL,
                mediaURLs: self.review.images
            )
        }
    }
}

// MARK: - BottomBar

struct BottomBar: View {

    // MARK: Properties

    @State var isUseful: Bool
    let usefulCount: Int

    @State private var moreButtonPressed: Bool = false

    // MARK: Content

    var body: some View {
        HStack(spacing: 5) {
            Button {
                self.isUseful.toggle()
                // like the review
            }
            label: {
                HStack(spacing: 5) {
                    Image(systemSymbol: self.isUseful ? .heartFill : .heart)
                        .foregroundStyle(self.isUseful ? Color.Colors.General._06DarkGreen : Color.Colors.General._02Grey)

                    Text(self.isUseful ? "Useful (\(self.usefulCount))" : "UseFul")
                        .hudhudFont(.footnote)
                        .foregroundStyle(self.isUseful ? Color.Colors.General._06DarkGreen : Color.Colors.General._02Grey)
                }
            }

            Spacer()

            Button {
                self.moreButtonPressed.toggle()
            }
            label: {
                Image(systemSymbol: .ellipsis)
                    .foregroundStyle(Color.Colors.General._02Grey)
            }
        }
        .confirmationDialog("", isPresented: self.$moreButtonPressed) {
            Button("Share") {}
            Button("Report", role: .destructive) {}
            Button("Cancel", role: .cancel) {}
        }
    }
}

#Preview {
    let review = Review(
        username: "Ahmad Kamal",
        userType: "Trip Advisor", userImage: URL(string: "https://img.freepik.com/free-photo/delicious-arabic-fast-food-skewers-black-plate_23-2148651145.jpg?w=740&t=st=1708506411~exp=1708507011~hmac=e3381fe61b2794e614de83c3f559ba6b712fd8d26941c6b49471d500818c9a77")!,
        rating: 4,
        date: "12 September 2024",
        reviewText: "Amazing blend of authentic Moroccan flavors with warm hospitality, making for an unforgettable dining experience.",
        images: [URL(string: "https://img.freepik.com/free-photo/delicious-arabic-fast-food-skewers-black-plate_23-2148651145.jpg?w=740&t=st=1708506411~exp=1708507011~hmac=e3381fe61b2794e614de83c3f559ba6b712fd8d26941c6b49471d500818c9a77")!],
        isUseful: false,
        usefulCount: 15
    )
    ReviewSectionView(review: review)
}
