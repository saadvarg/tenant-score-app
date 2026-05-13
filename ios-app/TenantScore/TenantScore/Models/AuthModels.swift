import Foundation

struct AuthRequest: Encodable {
    let email: String
    let password: String
}

struct AuthResponse: Decodable {
    let token: String
    let user: User
}

struct CurrentUserResponse: Decodable {
    let user: User
}

struct User: Decodable, Identifiable {
    let id: Int
    let email: String
    let role: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case role
        case createdAt = "created_at"
    }
}
