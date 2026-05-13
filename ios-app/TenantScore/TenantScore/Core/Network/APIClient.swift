import Foundation

final class APIClient {
    static let shared = APIClient()

    private let baseURL = URL(string: "http://localhost:5050/api")
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let tokenStore: TokenStore

    private init(
        session: URLSession = .shared,
        tokenStore: TokenStore = .shared
    ) {
        self.session = session
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        self.tokenStore = tokenStore
    }

    func get<Response: Decodable>(_ path: String, requiresAuth: Bool = true) async throws -> Response {
        try await request(path, method: "GET", body: Optional<String>.none, requiresAuth: requiresAuth)
    }

    func post<Request: Encodable, Response: Decodable>(
        _ path: String,
        body: Request,
        requiresAuth: Bool = true
    ) async throws -> Response {
        try await request(path, method: "POST", body: body, requiresAuth: requiresAuth)
    }

    func put<Request: Encodable, Response: Decodable>(
        _ path: String,
        body: Request,
        requiresAuth: Bool = true
    ) async throws -> Response {
        try await request(path, method: "PUT", body: body, requiresAuth: requiresAuth)
    }

    func patch<Request: Encodable, Response: Decodable>(
        _ path: String,
        body: Request,
        requiresAuth: Bool = true
    ) async throws -> Response {
        try await request(path, method: "PATCH", body: body, requiresAuth: requiresAuth)
    }

    func delete(_ path: String, requiresAuth: Bool = true) async throws {
        let _: EmptyResponse = try await request(path, method: "DELETE", body: Optional<String>.none, requiresAuth: requiresAuth)
    }

    private func request<Request: Encodable, Response: Decodable>(
        _ path: String,
        method: String,
        body: Request?,
        requiresAuth: Bool
    ) async throws -> Response {
        let cleanPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        guard let url = baseURL?.appending(path: cleanPath) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth {
            guard let token = tokenStore.load() else {
                throw APIError.requestFailed("Please log in again.")
            }

            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorResponse = try? decoder.decode(APIMessageResponse.self, from: data)
            throw APIError.requestFailed(errorResponse?.message ?? "Request failed.")
        }

        if data.isEmpty, Response.self == EmptyResponse.self {
            return EmptyResponse() as! Response
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decodingFailed
        }
    }
}

private struct APIMessageResponse: Decodable {
    let message: String
}

private struct EmptyResponse: Decodable {}
