import Foundation

protocol TenantServicing {
    func listTenants() async throws -> [Tenant]
    func createTenant(_ payload: TenantPayload) async throws -> Tenant
    func updateTenant(id: Int, payload: TenantPayload) async throws -> Tenant
    func updateTenantStatus(id: Int, status: ApplicationStatus, note: String?) async throws -> Tenant
    func listTenantEvents(id: Int) async throws -> [TenantEvent]
    func deleteTenant(id: Int) async throws
}

final class TenantService: TenantServicing {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func listTenants() async throws -> [Tenant] {
        let response: TenantsResponse = try await apiClient.get("/tenants")
        return response.tenants
    }

    func createTenant(_ payload: TenantPayload) async throws -> Tenant {
        let response: TenantResponse = try await apiClient.post("/tenants", body: payload)
        return response.tenant
    }

    func updateTenant(id: Int, payload: TenantPayload) async throws -> Tenant {
        let response: TenantResponse = try await apiClient.put("/tenants/\(id)", body: payload)
        return response.tenant
    }

    func updateTenantStatus(id: Int, status: ApplicationStatus, note: String?) async throws -> Tenant {
        let response: TenantResponse = try await apiClient.patch(
            "/tenants/\(id)/status",
            body: TenantStatusPayload(status: status, note: note)
        )
        return response.tenant
    }

    func listTenantEvents(id: Int) async throws -> [TenantEvent] {
        let response: TenantEventsResponse = try await apiClient.get("/tenants/\(id)/events")
        return response.events
    }

    func deleteTenant(id: Int) async throws {
        try await apiClient.delete("/tenants/\(id)")
    }
}
