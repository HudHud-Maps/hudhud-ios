//
//  LoginToSavePOIView.swift
//  HudHud
//
//  Created by Fatima Aljaber on 10/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

struct LoginToSavePOIView: View {

    // MARK: Properties

    var sheetStore: SheetStore
    @State var loginShown: Bool = false

    // MARK: Content

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button {
                self.sheetStore.popSheet()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.Colors.General._03LightGrey)
                        .frame(width: 30, height: 30)
                    Image(systemSymbol: .xmark)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.Colors.General._01Black)
                }
                .contentShape(Circle())
            }
            .padding(.top, 2)
            .padding(.trailing)
            .tint(.secondary)
            .accessibilityLabel(Text("Close", comment: "Accessibility label instead of x"))

            VStack(spacing: 24) {
                Image(uiImage: .POI_PIN)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                VStack(spacing: 12) {
                    Text("Log in to save this location")
                        .hudhudFontStyle(.headingXlarge)
                        .foregroundStyle(Color.Colors.General._01Black)

                    Text("To save this location you need to log In or sign up.")
                        .hudhudFontStyle(.paragraphMedium)
                        .foregroundStyle(Color.Colors.General._02Grey)
                }
                Button {
                    self.sheetStore.popSheet()
                    self.loginShown.toggle()
                } label: {
                    Text("Login or Sign up")
                }
                .buttonStyle(LargeButtonStyle(isLoading: .constant(false),
                                              backgroundColor: Color.Colors.General._06DarkGreen,
                                              foregroundColor: .white))
                .padding(.horizontal, 24)
            }
            .padding(.top)
        }
        .fullScreenCover(isPresented: self.$loginShown) {
            UserLoginView(loginStore: LoginStore())
                .toolbarRole(.editor)
        }
    }
}

#Preview {
    LoginToSavePOIView(sheetStore: .storeSetUpForPreviewing)
}
