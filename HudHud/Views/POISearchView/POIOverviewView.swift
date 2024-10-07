//
//  POIOverviewView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 06/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import SFSafeSymbols
import SwiftUI

// MARK: - POIOverviewView

struct POIOverviewView: View {

    // MARK: Properties

    let poiData: POISheetStore

    // MARK: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and Description
            Text(self.poiData.item.description)
                .hudhudFont(size: 14, fontWeight: .regular)
                .padding(.horizontal)
                .foregroundColor(Color.Colors.General._01Black)

            Divider()
                .background(Color.Colors.General._04GreyForLines)

            VStack(alignment: .leading, spacing: 15) {
                // Location Row
                LocationView(description: self.poiData.item.description)

                // Opening hours detial Row
                if let isOpen = poiData.item.isOpen {
                    OpeningHoursView(isOpen: isOpen, data: self.poiData)
                }

                // Contact detial Row
                if let phone = poiData.item.phone, let website = poiData.item.website?.absoluteString {
                    ContactDetailView(phone: phone, website: website)
                }

                Divider()
                    .background(Color.Colors.General._04GreyForLines)

                // Claim Button
                ClaimBusinessButton()
                    .padding(.horizontal)
            }
            .hudhudFont(size: 15, fontWeight: .regular)

            Divider()
                .background(Color.Colors.General._04GreyForLines)

            // Show more button
            ShowMoreButton()
                .padding(.horizontal)
        }
    }
}

// MARK: - LocationView

struct LocationView: View {

    // MARK: Properties

    let description: String

    // MARK: Content

    var body: some View {
        HStack {
            Image(systemSymbol: .mappinCircleFill)
                .foregroundColor(.Colors.General._02Grey)
            Text(self.description)
                .foregroundColor(.Colors.General._01Black)
        }
        .padding(.horizontal)
    }
}

// MARK: - OpeningHoursView

struct OpeningHoursView: View {

    // MARK: Properties

    let isOpen: Bool
    let data: POISheetStore

    // MARK: Content

    var body: some View {
        Button(action: {
            withAnimation { self.data.openingHours.toggle() }
        }) {
            HStack(alignment: .top) {
                Image(systemSymbol: .clockFill)
                    .foregroundColor(.Colors.General._02Grey)
                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Text(self.isOpen ? "Open" : "Closed")
                            .foregroundColor(self.isOpen ? .Colors.General._10GreenMain : .Colors.General._02Grey)
                        Image(systemName: self.data.openingHours ? "chevron.up" : "chevron.down")
                            .foregroundColor(Color.Colors.General._10GreenMain)
                    }

                    if self.data.openingHours {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(self.data.hours.keys.sorted(), id: \.self) { day in
                                HStack {
                                    Text(day)
                                        .hudhudFont(.caption)
                                        .foregroundColor(.Colors.General._02Grey)
                                    Spacer()
                                    Text(self.data.hours[day] ?? "")
                                        .hudhudFont(.caption)
                                        .foregroundColor(.Colors.General._02Grey)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - ContactDetailView

struct ContactDetailView: View {

    // MARK: Properties

    let phone: String
    let website: String

    @Environment(\.openURL) private var openURL

    // MARK: Content

    var body: some View {
        HStack(alignment: .top) {
            Image(systemSymbol: .exclamationmarkCircleFill)
                .foregroundColor(.Colors.General._02Grey)
            VStack(alignment: .leading, spacing: 7) {
                Button(action: {
                    if let url = URL(string: "tel://\(phone)") {
                        self.openURL(url)
                    }
                }) {
                    Text(self.phone)
                        .foregroundColor(.Colors.General._10GreenMain)
                }
                Link(self.website, destination: URL(string: self.website)!)
                    .foregroundColor(.Colors.General._10GreenMain)

                SocialMediaLinks()
                    .padding(.top, 12)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - SocialMediaLinks

// Social media

struct SocialMediaLinks: View {

    // MARK: Properties

    private let icons = ["Facebook", "tiktok", "x", "instgram"]

    // MARK: Content

    var body: some View {
        HStack(spacing: 20) {
            ForEach(self.icons, id: \.self) { icon in
                CircularIcon(iconName: icon)
            }
        }
    }
}

// MARK: - CircularIcon

struct CircularIcon: View {

    // MARK: Properties

    let iconName: String

    // MARK: Content

    //  let iconLink: URL

    var body: some View {
        Button {
            // open url
        } label: {
            Image(self.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)
                .foregroundColor(Color.Colors.General._01Black)
                .padding(12)
                .background(Circle()
                    .fill(Color.Colors.General._03LightGrey)
                    .frame(width: 40, height: 40)
                )
        }
    }
}

// MARK: - ClaimBusinessButton

struct ClaimBusinessButton: View {
    var body: some View {
        Button(action: {
            // Action for claim button
        }) {
            HStack {
                Image(systemSymbol: .checkmarkSealFill)
                    .foregroundColor(.Colors.General._02Grey)
                Text("Claim this business")
                    .foregroundColor(.Colors.General._06DarkGreen)
            }
        }
    }
}

// MARK: - ShowMoreButton

struct ShowMoreButton: View {
    var body: some View {
        Button(action: {
            // Action for show more button
        }) {
            Text("Show more")
                .foregroundColor(.Colors.General._06DarkGreen)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.Colors.General._03LightGrey)
                .cornerRadius(100)
        }
    }
}

#Preview {
    POIOverviewView(poiData: .init(item: .artwork, openingHours: false))
}
