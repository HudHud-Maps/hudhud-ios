//
//  ReviewsListView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 10/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - ReviewsListView

struct ReviewsListView: View {

    // MARK: Properties

    let reviews: [Review]

    // MARK: Content

    var body: some View {
        Section(header: ReviewsHeaderView(reviewsCount: self.reviews.count)) {
            List(self.reviews, id: \.id) { review in
                ReviewSectionView(review: review)
                    .padding(.vertical, 8)
            }
            .listStyle(.plain)
        }
    }
}

// MARK: - ReviewsHeaderView

struct ReviewsHeaderView: View {

    // MARK: Properties

    let reviewsCount: Int

    // MARK: Content

    var body: some View {
        HStack {
            Text("Reviews \(self.reviewsCount)")
                .hudhudFont(.headline)
                .foregroundColor(.Colors.General._01Black)
            Spacer()
            Button {
                // show filter by date
            }
            label: {
                HStack(spacing: 1) {
                    Text("By Date")
                    Image("arrowDown")
                }
                .hudhudFont(.headline)
                .foregroundColor(.Colors.General._06DarkGreen)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - ReviewSectionView

struct ReviewSectionView: View {

    // MARK: Properties

    let review: Review

    // MARK: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            UserView(review: self.review)
            RatingsView(review: self.review)
            Text(self.review.reviewText)
                .hudhudFont(.body)
                .lineLimit(nil)
                .foregroundColor(.Colors.General._01Black)
            ImageView(review: self.review)
                .padding(.vertical, 2)
            BottomBar(isUseful: self.review.isUseful, usefulCount: self.review.usefulCount)
        }
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
                    .foregroundColor(.Colors.General._02Grey)
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
                    Image(self.review.rating >= index ? .starOn : .starOff)
                        .resizable()
                        .frame(width: 14, height: 14)
                }
            }
            Text(self.review.date)
                .hudhudFont(.footnote)
                .foregroundColor(.Colors.General._02Grey)
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
            if let imageURL = review.images.first, review.images.count == 1 {
                AsyncImageView(imageURL: imageURL)
                    .onTapGesture {
                        self.selectedMedia = imageURL
                    }
            } else if self.review.images.count > 1 {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(self.review.images, id: \.self) { imageURL in
                            AsyncImageView(imageURL: imageURL)
                                .frame(width: 120, height: 120)
                                .onTapGesture {
                                    self.selectedMedia = imageURL
                                }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .sheet(item: self.$selectedMedia) { mediaURL in
            FullPageImage(mediaURL: mediaURL, mediaURLs: self.review.images)
        }
    }
}

// MARK: - AsyncImageView

struct AsyncImageView: View {

    // MARK: Properties

    let imageURL: URL

    // MARK: Content

    var body: some View {
        AsyncImage(url: self.imageURL) { image in
            image
                .resizable()
                .scaledToFill()
                .frame(width: .infinity, height: 168)
                .clipped()
                .contentShape(.rect)
        } placeholder: {
            ProgressView()
                .frame(width: .infinity, height: 168)
                .background(.secondary)
                .cornerRadius(10)
        }
        .background(.secondary)
        .cornerRadius(10)
    }
}

// MARK: - BottomBar

struct BottomBar: View {

    // MARK: Properties

    @State var isUseful: Bool
    @State private var moreButtonPressed: Bool = false
    let usefulCount: Int

    // MARK: Content

    var body: some View {
        HStack(spacing: 5) {
            Button {
                self.isUseful.toggle()
            }
            label: {
                HStack(spacing: 5) {
                    Image(systemSymbol: self.isUseful ? .heartFill : .heart)
                        .foregroundColor(self.isUseful ? .Colors.General._06DarkGreen : .Colors.General._02Grey)

                    Text(self.isUseful ? "Useful (\(self.usefulCount))" : "UseFul")
                        .hudhudFont(.footnote)
                        .foregroundColor(self.isUseful ? .Colors.General._06DarkGreen : .Colors.General._02Grey)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                self.moreButtonPressed.toggle()
            }
            label: {
                Image(systemSymbol: .ellipsis)
                    .foregroundColor(.Colors.General._02Grey)
            }
            .buttonStyle(.plain)
                .confirmationDialog("", isPresented: self.$moreButtonPressed) {
                    Button("Share") {}
                    Button("Report", role: .destructive) {}
                    Button("Cancel", role: .cancel) {}
                }
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

#Preview {
    let reviews = [Review(
        username: "Ahmad Kamal",
        userType: "Trip Advisor", userImage: URL(string: "https://img.freepik.com/free-photo/delicious-arabic-fast-food-skewers-black-plate_23-2148651145.jpg?w=740&t=st=1708506411~exp=1708507011~hmac=e3381fe61b2794e614de83c3f559ba6b712fd8d26941c6b49471d500818c9a77")!,
        rating: 4,
        date: "12 September 2024",
        reviewText: "Amazing blend of authentic Moroccan flavors with warm hospitality, making for an unforgettable dining experience.",
        images: [URL(string: "https://img.freepik.com/free-photo/delicious-arabic-fast-food-skewers-black-plate_23-2148651145.jpg?w=740&t=st=1708506411~exp=1708507011~hmac=e3381fe61b2794e614de83c3f559ba6b712fd8d26941c6b49471d500818c9a77")!],
        isUseful: false,
        usefulCount: 15
    ), Review(
        username: "Noura Ahmed",
        userType: "Trip Advisor", userImage: URL(string: "https://img.freepik.com/free-photo/delicious-arabic-fast-food-skewers-black-plate_23-2148651145.jpg?w=740&t=st=1708506411~exp=1708507011~hmac=e3381fe61b2794e614de83c3f559ba6b712fd8d26941c6b49471d500818c9a77")!,
        rating: 4,
        date: "12 September 2024",
        reviewText: "Amazing blend of authentic Moroccan flavors with warm hospitality, making for an unforgettable dining experience.",
        images: [URL(string: "https://img.freepik.com/free-photo/delicious-arabic-fast-food-skewers-black-plate_23-2148651145.jpg?w=740&t=st=1708506411~exp=1708507011~hmac=e3381fe61b2794e614de83c3f559ba6b712fd8d26941c6b49471d500818c9a77")!, URL(string: "https://img.freepik.com/free-photo/delicious-arabic-fast-food-skewers-black-plate_23-2148651145.jpg?w=740&t=st=1708506411~exp=1708507011~hmac=e3381fe61b2794e614de83c3f559ba6b712fd8d26941c6b49471d500818c9a77")!, URL(string: "https://img.freepik.com/free-photo/delicious-arabic-fast-food-skewers-black-plate_23-2148651145.jpg?w=740&t=st=1708506411~exp=1708507011~hmac=e3381fe61b2794e614de83c3f559ba6b712fd8d26941c6b49471d500818c9a77")!],
        isUseful: false,
        usefulCount: 15
    )]
    ReviewsListView(reviews: reviews)
}
