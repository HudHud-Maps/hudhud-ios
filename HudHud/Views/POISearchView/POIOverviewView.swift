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

    // MARK: Nested Types

    enum Tab: String, CaseIterable, CustomStringConvertible {
        case overview
        case review
        case photos
        case similar
        case about

        // MARK: Computed Properties

        var description: String {
            switch self {
            case .overview:
                return NSLocalizedString("Overview", comment: "Overview Tab in POI Details")
            case .review:
                return NSLocalizedString("Reviews", comment: "Reviews Tab in POI Details")
            case .photos:
                return NSLocalizedString("Photos", comment: "Photos Tab in POI Details")
            case .similar:
                return NSLocalizedString("Similar Places", comment: "Similar Places Tab in POI Details")
            case .about:
                return NSLocalizedString("About", comment: "About Tab in POI Details")
            }
        }
    }

    // MARK: Properties

    let poiData: POISheetStore
    @State var viewMore: Bool = false
    @Binding var selectedTab: Tab

    // MARK: Computed Properties

    private var shouldShowButton: Bool {
        let maxCharacters = 250
        return (self.poiData.item.description).count > maxCharacters
    }

    // MARK: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Here should be a description not the address
            SectionView(description: self.poiData.item.description)
                .lineLimit(self.viewMore ? 30 : 7)
            if self.shouldShowButton {
                Button(self.viewMore ? "Show Less" : "Show More") {
                    self.viewMore.toggle()
                }
            }
            Divider()
                .background(Color.Colors.General._04GreyForLines)

            VStack(alignment: .leading, spacing: 15) {
                // Location Row
                SectionView(image: .mapPin, description: self.poiData.item.description)
                Divider()
                    .background(Color.Colors.General._04GreyForLines)
                // Floor
                if let floor = self.poiData.item.floor, self.selectedTab == .about {
                    SectionView(image: .building, description: floor)

                    Divider()
                        .background(Color.Colors.General._04GreyForLines)
                }
                // National Address
                if let nationalAddress = poiData.item.nationalAddress, self.selectedTab == .about {
                    SectionView(image: .nationalAddress, title: "National Address", description: nationalAddress)

                    Divider()
                        .frame(height: 1)
                        .background(Color.Colors.General._04GreyForLines)
                }
                // Price Range
                if let priceRangeValue = self.poiData.item.priceRange,
                   let priceRange = HudHudPOI.PriceRange(rawValue: priceRangeValue), self.selectedTab == .about {
                    SectionView(sfSymbol: .dollarsignCircleFill, title: nil, description: priceRange.displayValue)

                    Divider()
                        .background(Color.Colors.General._04GreyForLines)
                }

                // Opening hours detail Row
                if let isOpen = poiData.item.isOpen {
                    OpeningHoursView(isOpen: isOpen, data: self.poiData)
                }

                // Contact detail Row
                if let phone = poiData.item.phone, let website = poiData.item.website?.absoluteString {
                    ContactDetailView(phone: phone, website: website)
                    Divider()
                        .background(Color.Colors.General._04GreyForLines)
                }

                // Claim Button
                ClaimBusinessButtonView()
                    .padding(.horizontal)
            }
            .hudhudFont(size: 15, fontWeight: .regular)

            // if tab == overview
            if self.selectedTab != .about {
                Divider()
                    .background(Color.Colors.General._04GreyForLines)

                // Show more button
                ShowMoreButtonView {
                    self.selectedTab = .about
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(.white)
        .cornerRadius(20)
    }
}

// MARK: - SectionView

struct SectionView: View {

    // MARK: Properties

    let image: ImageResource?
    let sfSymbol: SFSymbol?
    let title: String?
    let description: String

    // MARK: Lifecycle

    init(
        image: ImageResource? = nil,
        sfSymbol: SFSymbol? = nil,
        title: String? = nil,
        description: String
    ) {
        self.image = image
        self.sfSymbol = sfSymbol
        self.title = title
        self.description = description
    }

    // MARK: Content

    var body: some View {
        HStack {
            // icon
            if let sfSymbol {
                Image(systemSymbol: sfSymbol)
                    .font(.title3)
                    .foregroundStyle(Color.gray.opacity(0.5))
            }
            if let image {
                Image(image)
                    .font(.title3)
                    .foregroundStyle(Color.gray.opacity(0.5))
            }
            // Text
            VStack(alignment: .leading) {
                if let title {
                    Text(title)
                        .hudhudFont(size: 14, fontWeight: .regular)
                        .foregroundColor(.Colors.General._02Grey)
                }
                Text(self.description)
                    .hudhudFont(size: 14, fontWeight: .regular)
                    .foregroundColor(.Colors.General._01Black)
            }
            .padding(.leading, 5)
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
            withAnimation { self.data.openingHoursExpanded.toggle() }
        }, label: {
            HStack(alignment: .top) {
                Image(systemSymbol: .clockFill)
                    .font(.title3)
                    .foregroundStyle(Color.gray.opacity(0.6))
                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Text(self.isOpen ? "Open" : "Closed")
                            .foregroundColor(self.isOpen ? .Colors.General._06DarkGreen : .Colors.General._02Grey)
                        Image(systemSymbol: self.data.openingHoursExpanded ? .chevronUp : .chevronDown)
                            .foregroundColor(Color.Colors.General._06DarkGreen)
                    }

                    if self.data.openingHoursExpanded {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(POISheetStore.OpeningHours.allCases, id: \.self) { day in
                                HStack {
                                    Text(day.rawValue)
                                        .hudhudFont(.caption)
                                        .foregroundColor(.Colors.General._02Grey)
                                    Spacer()
                                    Text(day.hours)
                                        .hudhudFont(.caption)
                                        .foregroundColor(.Colors.General._02Grey)
                                }
                            }
                        }
                    }
                }
            }
        })
        .padding(.horizontal)
    }
}

// MARK: - ContactDetailView

struct ContactDetailView: View {

    // MARK: Properties

    let phone: String?
    let website: String?

    @Environment(\.openURL) private var openURL

    // MARK: Content

    var body: some View {
        HStack(alignment: .top) {
            Image(systemSymbol: .exclamationmarkCircleFill)
                .font(.title3)
                .foregroundStyle(Color.gray.opacity(0.5))
            VStack(alignment: .leading, spacing: 7) {
                if let phone {
                    Button(action: {
                        if let url = URL(string: "tel://\(phone)") {
                            self.openURL(url)
                        }
                    }, label: {
                        Text(phone)
                            .foregroundColor(.Colors.General._06DarkGreen)
                            .padding(.top, 2)
                    })
                }
                if let website, let url = URL(string: website) {
                    Link(website, destination: url)
                        .foregroundColor(.Colors.General._06DarkGreen)

                    SocialMediaLinksView()
                        .padding(.top, 12)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - SocialMediaLinksView

// Social media

struct SocialMediaLinksView: View {

    // MARK: Properties

    private let icons = ["Facebook", "tiktok", "x", "instgram"]

    // MARK: Content

    var body: some View {
        HStack(spacing: 20) {
            ForEach(self.icons, id: \.self) { icon in
                CircularIconView(iconName: icon)
            }
        }
    }
}

// MARK: - CircularIconView

struct CircularIconView: View {

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

// MARK: - ClaimBusinessButtonView

struct ClaimBusinessButtonView: View {
    var body: some View {
        Button(action: {
            // Action for claim button
        }, label: {
            HStack {
                Image(systemSymbol: .checkmarkSealFill)
                    .foregroundColor(.Colors.General._02Grey)
                Text("Claim this business")
                    .foregroundColor(.Colors.General._06DarkGreen)
            }
        })
    }
}

// MARK: - ShowMoreButtonView

struct ShowMoreButtonView: View {

    // MARK: Properties

    let action: () -> Void

    // MARK: Content

    var body: some View {
        Button {
            self.action()
        } label: {
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
    @Previewable @State var overview: POIOverviewView.Tab = .overview
    POIOverviewView(poiData: POISheetStore(item: .artwork), selectedTab: $overview)
}

#Preview("About") {
    @Previewable @State var about: POIOverviewView.Tab = .about
    POIOverviewView(poiData: POISheetStore(item: .ketchup), selectedTab: $about)
}
