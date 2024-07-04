//
//  ErrorView.swift
//  HudHud
//
//  Created by Patrick Kladek on 09.04.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI

// MARK: - ErrorView

struct ErrorView: View {

    let error: Error

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(self.error.title)
                .bold()
            if let message = self.error.message {
                Text(message)
                    .hudhudFont(.medium, size: 15)
            }
            if let hint = self.error.hint {
                Text(hint)
                    .hudhudFont(.medium, size: 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundColor(Color.white)
        .padding(12)
        .background(.red)
        .cornerRadius(8)
    }
}

// MARK: - Private

private extension Error {

    var title: String {
        if let error = self as? LocalizedError, let description = error.errorDescription {
            return description
        }

        return self.localizedDescription
    }

    var message: String? {
        guard let error = self as? LocalizedError else {
            return nil
        }

        return error.failureReason
    }

    var hint: String? {
        guard let error = self as? LocalizedError else {
            return nil
        }

        return error.recoverySuggestion
    }
}

#Preview {
    ErrorView(error: StreetViewWebView.StreetViewError.invalidURL)
}
