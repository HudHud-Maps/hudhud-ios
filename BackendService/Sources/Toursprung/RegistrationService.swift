//
//  RegistrationService.swift
//  BackendService
//
//  Created by Fatima Aljaber on 13/09/2024.

import CoreLocation
import Foundation
import MapKit
import OpenAPIURLSession
import OSLog
import SwiftUI

// MARK: - RegistrationService

public class RegistrationService: ObservableObject {

    // MARK: Properties

    @Published public var registrationData: RegistrationResponse?
    @Published public var lastError: Error?

    // MARK: Lifecycle

    public init() {}

    // MARK: Functions

    public func login(loginInput: String, baseURL: String) async throws -> RegistrationResponse {
        let urlSessionConfiguration = URLSessionConfiguration.default
        urlSessionConfiguration.waitsForConnectivity = true
        urlSessionConfiguration.timeoutIntervalForResource = 60 // seconds

        let urlSession = URLSession(configuration: urlSessionConfiguration)
        let transportConfiguration = URLSessionTransport.Configuration(session: urlSession)
        let transport = URLSessionTransport(configuration: transportConfiguration)

        let response = try await Client.makeClient(using: baseURL, transport: transport).login(headers: .init(Accept_hyphen_Language: Locale.preferredLanguages.first ?? "en-US"), body: .json(.init(login_identity: loginInput)))
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

                return RegistrationResponse(id: id, loginIdentity: loginIdentity, canRequestOtpResendAt: canRequestOtpResendAt)
            }
        case let .undocumented(statusCode: statusCode, payload):
            let bodyString: String? = if let body = payload.body {
                try await String(collecting: body, upTo: 1024 * 1024)
            } else {
                nil
            }
            self.lastError = OpenAPIClientError.undocumentedAnswer(status: statusCode, body: bodyString)
            throw OpenAPIClientError.undocumentedAnswer(status: statusCode, body: bodyString)
        case let .badRequest(error):
            throw try HudHudClientError.internalServerError(error.body.json.message.debugDescription)
        }
    }

}

// MARK: - RegistrationResponse

public struct RegistrationResponse: Codable, Hashable {

    // MARK: Nested Types

    enum CodingKeys: String, CodingKey {
        case id
        case loginIdentity = "login_identity"
        case canRequestOtpResendAt = "can_request_otp_resend_at"
    }

    // MARK: Properties

    public let id, loginIdentity: String
    public let canRequestOtpResendAt: String

    // MARK: Computed Properties

    public var otpResendDate: Date? {
        let dateFormatter = ISO8601DateFormatter()
        return dateFormatter.date(from: self.canRequestOtpResendAt)
    }

    // MARK: Functions

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
        hasher.combine(self.loginIdentity)
        hasher.combine(self.canRequestOtpResendAt)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.loginIdentity, forKey: .loginIdentity)
        try container.encode(self.canRequestOtpResendAt, forKey: .canRequestOtpResendAt)
    }

}
