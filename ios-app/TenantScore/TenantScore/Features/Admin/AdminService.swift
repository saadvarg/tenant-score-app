import Foundation

protocol AdminServicing {
    func getStats() async throws -> AdminStats
    func listUsers() async throws -> [AdminUser]
    func listTenants() async throws -> [Tenant]
    func listTenantEvents(id: Int) async throws -> [TenantEvent]
    func deleteTenant(id: Int) async throws
}

final class AdminService: AdminServicing {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func getStats() async throws -> AdminStats {
        let response: AdminStatsResponse = try await apiClient.get("/admin/stats")
        return response.stats
    }

    func listUsers() async throws -> [AdminUser] {
        let response: AdminUsersResponse = try await apiClient.get("/admin/users")
        return response.users
    }

    func listTenants() async throws -> [Tenant] {
        let response: TenantsResponse = try await apiClient.get("/admin/tenants")
        return response.tenants
    }

    func listTenantEvents(id: Int) async throws -> [TenantEvent] {
        let response: TenantEventsResponse = try await apiClient.get("/admin/tenants/\(id)/events")
        return response.events
    }

    func deleteTenant(id: Int) async throws {
        try await apiClient.delete("/admin/tenants/\(id)")
    }
}
