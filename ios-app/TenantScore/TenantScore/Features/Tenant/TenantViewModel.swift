import Combine
import Foundation

@MainActor
final class TenantViewModel: ObservableObject {
    @Published private(set) var tenants: [Tenant] = []
    @Published var searchText = ""
    @Published var selectedRiskFilter: TenantRiskFilter = .all
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let tenantService: TenantServicing

    init(tenantService: TenantServicing? = nil) {
        self.tenantService = tenantService ?? TenantService()
    }

    var lowRiskCount: Int {
        tenants.filter { $0.riskLevel == .low }.count
    }

    var mediumRiskCount: Int {
        tenants.filter { $0.riskLevel == .medium }.count
    }

    var highRiskCount: Int {
        tenants.filter { $0.riskLevel == .high }.count
    }

    var averageScore: Int {
        guard !tenants.isEmpty else { return 0 }
        return tenants.map(\.riskScore).reduce(0, +) / tenants.count
    }

    var filteredTenants: [Tenant] {
        tenants.filter { tenant in
            let matchesRisk: Bool

            switch selectedRiskFilter {
            case .all:
                matchesRisk = true
            case .low:
                matchesRisk = tenant.riskLevel == .low
            case .medium:
                matchesRisk = tenant.riskLevel == .medium
            case .high:
                matchesRisk = tenant.riskLevel == .high
            }

            let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedSearch.isEmpty else {
                return matchesRisk
            }

            return matchesRisk && (
                tenant.fullName.localizedCaseInsensitiveContains(trimmedSearch) ||
                (tenant.email?.localizedCaseInsensitiveContains(trimmedSearch) ?? false) ||
                (tenant.phone?.localizedCaseInsensitiveContains(trimmedSearch) ?? false)
            )
        }
    }

    func loadTenants() async {
        isLoading = true
        errorMessage = nil

        do {
            tenants = try await tenantService.listTenants()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func saveTenant(id: Int?, payload: TenantPayload) async -> Bool {
        errorMessage = nil

        do {
            if let id {
                let updatedTenant = try await tenantService.updateTenant(id: id, payload: payload)
                if let index = tenants.firstIndex(where: { $0.id == id }) {
                    tenants[index] = updatedTenant
                }
            } else {
                let newTenant = try await tenantService.createTenant(payload)
                tenants.insert(newTenant, at: 0)
            }

            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func deleteTenant(_ tenant: Tenant) async {
        errorMessage = nil

        do {
            try await tenantService.deleteTenant(id: tenant.id)
            tenants.removeAll { $0.id == tenant.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateStatus(for tenant: Tenant, status: ApplicationStatus, note: String? = nil) async {
        errorMessage = nil

        do {
            let updatedTenant = try await tenantService.updateTenantStatus(id: tenant.id, status: status, note: note)
            if let index = tenants.firstIndex(where: { $0.id == tenant.id }) {
                tenants[index] = updatedTenant
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadEvents(for tenant: Tenant) async -> [TenantEvent] {
        do {
            return try await tenantService.listTenantEvents(id: tenant.id)
        } catch {
            errorMessage = error.localizedDescription
            return []
        }
    }
}

enum TenantRiskFilter: String, CaseIterable, Identifiable {
    case all
    case low
    case medium
    case high

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }
}
