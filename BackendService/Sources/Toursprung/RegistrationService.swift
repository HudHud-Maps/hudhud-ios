//
//  RegistrationService.swift
//  BackendService
//
//  Created by Fatima Aljaber on 13/09/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation
import MapKit
import OpenAPIURLSession
import OSLog
import SwiftUI

// MARK: - RegistrationService

public struct RegistrationService {

    // MARK: Lifecycle

    public init() {}

    // MARK: Functions

    public mutating func login(loginInput: String, baseURL: String) async throws -> RegistrationResponse {
        let urlSessionConfiguration = URLSessionConfiguration.default
        urlSessionConfiguration.waitsForConnectivity = true
        urlSessionConfiguration.timeoutIntervalForResource = 60 // seconds

        let urlSession = URLSession(configuration: urlSessionConfiguration)
        let transportConfiguration = URLSessionTransport.Configuration(session: urlSession)
        let transport = URLSessionTransport(configuration: transportConfiguration)
        let body = Operations.login.Input.Body.json(
            Components.Schemas.LoginRequest(login_identity: loginInput)
        )
        let headers = Operations.login.Input.Headers(
            Accept_hyphen_Language: Locale.preferredLanguages.first ?? "en-US"
        )
        let response = try await Client.makeClient(using: baseURL, transport: transport).login(headers: headers, body: body)

        switch response {
        case let .created(okResponse):
            switch okResponse.body {
            case let .json(jsonResponse):
                guard
                    let id = jsonResponse.data.value1.id,
                    let loginIdentity = jsonResponse.data.value1.login_identity,
                    let canRequestOtpResendAt = jsonResponse.data.value1.can_request_otp_resend_at else {
                    throw HudHudClientError.internalServerError("login failed")
                }
                return RegistrationResponse(id: id, loginIdentity: loginIdentity, canRequestOtpResendAt: self.date(from: canRequestOtpResendAt))
            }
        case let .undocumented(statusCode: statusCode, payload):
            let bodyString: String? = if let body = payload.body {
                try await String(collecting: body, upTo: 1024 * 1024)
            } else {
                nil
            }
            throw OpenAPIClientError.undocumentedAnswer(status: statusCode, body: bodyString)
        case let .badRequest(error):
            throw try HudHudClientError.internalServerError(error.body.json.message.debugDescription)
        }
    }

    func date(from canRequestOtpResendAt: String) -> Date {
        let dateFormatter = ISO8601DateFormatter()
        // If parsing fails, return a date that is 30 seconds from now
        return dateFormatter.date(from: canRequestOtpResendAt) ?? Date().addingTimeInterval(30)
    }
}

// MARK: - RegistrationResponse

public struct RegistrationResponse {

    public let id, loginIdentity: String
    public let canRequestOtpResendAt: Date
}
