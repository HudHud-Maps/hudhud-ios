//
//  ClientExtension.swift
//  Hudhud
//
//  Created by Fatima Aljaber on 11/08/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import APIClient
import Foundation
import OpenAPIRuntime

extension Client {

    static func makeClient(using baseURLString: String) -> Client {
        if let baseURL = URL(string: baseURLString) {
            return Client(serverURL: baseURL, transport: APIClient.transport, middlewares: [
                AuthenticationMiddleware(authorizationHeaderFieldValue: "123")
            ])
        } else {
            let fallbackURL = URL(string: "https://api.dev.hudhud.sa")! // swiftlint:disable:this force_unwrapping
            return Client(serverURL: fallbackURL, transport: APIClient.transport, middlewares: [
                AuthenticationMiddleware(authorizationHeaderFieldValue: "123")
            ])
        }
    }
}
