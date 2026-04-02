import Foundation

struct Attendee: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let title: String
    let company: String
    let linkedinURL: String
    let email: String?
    let phone: String?

    var firstName: String {
        let components = name.split(separator: " ")
        return String(components.first ?? "")
    }

    var lastName: String {
        let components = name.split(separator: " ")
        return components.dropFirst().joined(separator: " ")
    }

    init(id: UUID = UUID(), name: String, title: String, company: String, linkedinURL: String, email: String? = nil, phone: String? = nil) {
        self.id = id
        self.name = name
        self.title = title
        self.company = company
        self.linkedinURL = linkedinURL
        self.email = email
        self.phone = phone
    }
}

struct RegistrationRecord: Identifiable {
    let id: UUID
    let attendee: Attendee
    let registeredAt: Date
    var envoySignInSuccess: Bool
    var badgePrinted: Bool

    init(attendee: Attendee, envoySignInSuccess: Bool = false, badgePrinted: Bool = false) {
        self.id = UUID()
        self.attendee = attendee
        self.registeredAt = Date()
        self.envoySignInSuccess = envoySignInSuccess
        self.badgePrinted = badgePrinted
    }
}
