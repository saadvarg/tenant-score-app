import Foundation

protocol AuthServicing {
    func login(email: String, password: String) async throws -> AuthResponse
    func signup(email: String, password: String) async throws -> AuthResponse
    func currentUser() async throws -> User
}

final class AuthService: AuthServicing {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        try await apiClient.post("/auth/login", body: AuthRequest(email: email, password: password), requiresAuth: false)
    }

    func signup(email: String, password: String) async throws -> AuthResponse {
        try await apiClient.post("/auth/signup", body: AuthRequest(email: email, password: password), requiresAuth: false)
    }

    func currentUser() async throws -> User {
        let response: CurrentUserResponse = try await apiClient.get("/auth/me")
        return response.user
    }
}
