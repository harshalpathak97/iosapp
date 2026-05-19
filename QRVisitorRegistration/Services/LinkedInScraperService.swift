import Foundation

/// Client for the LinkedIn scraper backend (see /backend in this repo).
///
/// Used as a fallback when a scanned LinkedIn URL is not found in the
/// local attendees.json. Sends the URL to the backend, which scrapes
/// the profile and returns name/title/company.
class LinkedInScraperService: ObservableObject {
    @Published var isConfigured: Bool = false

    private var backendURL: String = ""
    private var sharedSecret: String = ""

    func configure(backendURL: String, sharedSecret: String) {
        self.backendURL = backendURL.trimmingCharacters(in: .whitespacesAndNewlines)
        self.sharedSecret = sharedSecret.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isConfigured = !self.backendURL.isEmpty && !self.sharedSecret.isEmpty

        UserDefaults.standard.set(self.backendURL, forKey: "scraper_backend_url")
        UserDefaults.standard.set(self.sharedSecret, forKey: "scraper_shared_secret")
    }

    func loadSavedConfiguration() {
        let url = UserDefaults.standard.string(forKey: "scraper_backend_url") ?? ""
        let secret = UserDefaults.standard.string(forKey: "scraper_shared_secret") ?? ""
        configure(backendURL: url, sharedSecret: secret)
    }

    /// Scrape a LinkedIn profile via the backend.
    /// Returns a freshly-built Attendee (UUID auto-generated, no email/phone).
    func scrapeProfile(linkedinURL: String) async throws -> Attendee {
        guard isConfigured else { throw ScraperError.notConfigured }
        guard let endpoint = URL(string: "\(backendURL)/scrape") else {
            throw ScraperError.networkError("Invalid backend URL")
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 60 // scraping can take 10-30s
        request.setValue("Bearer \(sharedSecret)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = ["linkedinURL": linkedinURL]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ScraperError.networkError("No HTTP response")
        }

        switch http.statusCode {
        case 200:
            let decoded = try JSONDecoder().decode(ScrapeResponse.self, from: data)
            return Attendee(
                name: decoded.name,
                title: decoded.title ?? "",
                company: decoded.company ?? "",
                linkedinURL: decoded.linkedinURL ?? linkedinURL
            )
        case 401:
            throw ScraperError.unauthorized
        case 404:
            throw ScraperError.profileNotAccessible
        case 429:
            throw ScraperError.rateLimited
        default:
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ScraperError.networkError("Backend error (\(http.statusCode)): \(errorBody)")
        }
    }
}

private struct ScrapeResponse: Decodable {
    let name: String
    let title: String?
    let company: String?
    let headline: String?
    let linkedinURL: String?
    let cached: Bool?
}

enum ScraperError: LocalizedError {
    case notConfigured
    case unauthorized
    case profileNotAccessible
    case rateLimited
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Scraper backend not configured. Add the backend URL and shared secret in Settings."
        case .unauthorized:
            return "Backend rejected the shared secret, or the LinkedIn session cookie expired."
        case .profileNotAccessible:
            return "LinkedIn profile is private or not found."
        case .rateLimited:
            return "LinkedIn rate-limited the scrape. Try again in a few minutes."
        case .networkError(let detail):
            return "Network error: \(detail)"
        }
    }
}
