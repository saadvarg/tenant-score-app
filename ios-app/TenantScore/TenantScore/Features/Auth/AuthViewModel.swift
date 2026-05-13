import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isSignupMode = false
    @Published var isLoading = false
    @Published var isRestoringSession = false
    @Published var errorMessage: String?
    @Published private(set) var user: User?
    @Published private(set) var isAuthenticated: Bool

    private let authService: AuthServicing
    private let tokenStore: TokenStore

    init(
        authService: AuthServicing? = nil,
        tokenStore: TokenStore? = nil
    ) {
        let resolvedAuthService = authService ?? AuthService()
        let resolvedTokenStore = tokenStore ?? .shared

        self.authService = resolvedAuthService
        self.tokenStore = resolvedTokenStore
        self.isAuthenticated = resolvedTokenStore.load() != nil
    }

    func restoreSession() async {
        guard tokenStore.load() != nil, user == nil else {
            return
        }

        isRestoringSession = true
        errorMessage = nil

        do {
            user = try await authService.currentUser()
            isAuthenticated = true
        } catch {
            tokenStore.clear()
            user = nil
            isAuthenticated = false
            errorMessage = nil
        }

        isRestoringSession = false
    }

    func submit() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password are required."
            return
        }

        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let response: AuthResponse

            if isSignupMode {
                response = try await authService.signup(email: trimmedEmail, password: password)
            } else {
                response = try await authService.login(email: trimmedEmail, password: password)
            }

            tokenStore.save(response.token)
            user = response.user
            isAuthenticated = true
            password = ""
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func logout() {
        tokenStore.clear()
        user = nil
        isAuthenticated = false
        isRestoringSession = false
        password = ""
    }
}
