import Foundation

/// Integration service for the Envoy Visitor Registration system.
///
/// Envoy provides a REST API for managing visitor sign-ins. This service handles
/// creating visitor entries and triggering the sign-in flow.
///
/// Setup:
/// 1. Obtain an API key from your Envoy dashboard (Settings > Integrations > API)
/// 2. Configure your location ID from the Envoy dashboard
/// 3. Set the values in the app's Settings screen
class EnvoyService: ObservableObject {
    @Published var isConfigured: Bool = false
    @Published var lastError: String?

    private var apiKey: String = ""
    private var locationID: String = ""
    private var baseURL: String = "https://app.envoy.com/api/v3"

    // MARK: - Configuration

    func configure(apiKey: String, locationID: String) {
        self.apiKey = apiKey
        self.locationID = locationID
        self.isConfigured = !apiKey.isEmpty && !locationID.isEmpty

        // Persist configuration
        UserDefaults.standard.set(apiKey, forKey: "envoy_api_key")
        UserDefaults.standard.set(locationID, forKey: "envoy_location_id")
    }

    func loadSavedConfiguration() {
        let savedKey = UserDefaults.standard.string(forKey: "envoy_api_key") ?? ""
        let savedLocation = UserDefaults.standard.string(forKey: "envoy_location_id") ?? ""
        configure(apiKey: savedKey, locationID: savedLocation)
    }

    // MARK: - Visitor Sign-In

    /// Sign in a visitor through the Envoy API
    func signInVisitor(attendee: Attendee) async throws -> EnvoySignInResult {
        guard isConfigured else {
            throw EnvoyError.notConfigured
        }

        let url = URL(string: "\(baseURL)/invites")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "data": [
                "type": "invites",
                "attributes": [
                    "expected-arrival-at": ISO8601DateFormatter().string(from: Date()),
                    "private-notes": "Registered via QR Scanner App"
                ],
                "relationships": [
                    "location": [
                        "data": [
                            "type": "locations",
                            "id": locationID
                        ]
                    ]
                ]
            ],
            "meta": [
                "visitor-name": attendee.name,
                "visitor-email": attendee.email ?? "",
                "visitor-company": attendee.company,
                "visitor-title": attendee.title
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EnvoyError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return EnvoySignInResult(success: true, message: "Visitor signed in successfully")
        case 401:
            throw EnvoyError.unauthorized
        case 422:
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown validation error"
            throw EnvoyError.validationError(errorBody)
        default:
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw EnvoyError.apiError(httpResponse.statusCode, errorBody)
        }
    }

    /// Alternative: Open the Envoy Visitor app via URL scheme with pre-filled data
    /// This is useful when direct API access is not available
    func openEnvoyApp(for attendee: Attendee) -> Bool {
        // Envoy Visitors iPad app supports URL schemes for sign-in
        var components = URLComponents()
        components.scheme = "envoy"
        components.host = "sign-in"
        components.queryItems = [
            URLQueryItem(name: "name", value: attendee.name),
            URLQueryItem(name: "email", value: attendee.email ?? ""),
            URLQueryItem(name: "company", value: attendee.company),
            URLQueryItem(name: "title", value: attendee.title),
        ]

        guard let url = components.url else { return false }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return true
        }
        return false
    }
}

struct EnvoySignInResult {
    let success: Bool
    let message: String
}

enum EnvoyError: LocalizedError {
    case notConfigured
    case unauthorized
    case invalidResponse
    case validationError(String)
    case apiError(Int, String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Envoy API is not configured. Please add your API key and location ID in Settings."
        case .unauthorized:
            return "Invalid Envoy API key. Please check your credentials in Settings."
        case .invalidResponse:
            return "Received an invalid response from Envoy."
        case .validationError(let detail):
            return "Envoy validation error: \(detail)"
        case .apiError(let code, let detail):
            return "Envoy API error (\(code)): \(detail)"
        }
    }
}

import UIKit
